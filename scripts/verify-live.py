#!/usr/bin/env python3
"""Check the deployed app and compare its Fusion state across a Studio restart.

Record once, stop/start the Studio with tw, then verify against the same record.
No provider calls or credential values are read or stored.
"""
import argparse
import json
import shlex
import subprocess
from pathlib import Path
from datetime import datetime, timezone
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('mode', choices=['record', 'verify'])
parser.add_argument('--workspace', required=True)
parser.add_argument('--studio-id', required=True)
parser.add_argument('--ssh-key', required=True)
parser.add_argument('--evidence', type=Path, required=True)
parser.add_argument('--tw', default='tw')
args = parser.parse_args()

def run(command, **kwargs):
    result = subprocess.run(command, capture_output=True, text=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {result.stderr.strip()}')
    return result.stdout

studio = json.loads(run([args.tw, '-o', 'json', 'studios', 'view',
                         '-w', args.workspace, '--id', args.studio_id]))['studio']
assert studio['statusInfo']['status'] == 'running', studio['statusInfo']
assert studio['isPrivate'], 'Expected a private Studio'
assert studio['configuration']['environment'].get('PI_LOCAL_STORAGE') != '1'
ssh = studio['sshDetails']
marker = 'pi-durable-live-' + str(uuid.uuid4()) if args.mode == 'record' else json.loads(args.evidence.read_text())['marker']
expected_main = None if args.mode == 'record' else json.loads(args.evidence.read_text())['mainFile']
script = r'''
import { readFile, writeFile, open, statfs, readdir, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const mode = MODE;
let marker = MARKER;
const expectedMain = EXPECTED_MAIN;
const base = `http://127.0.0.1:${process.env.CONNECT_TOOL_PORT}`;
const healthResponse = await fetch(`${base}/healthz`);
if (!healthResponse.ok) throw new Error('Health HTTP request failed');
const health = await healthResponse.json();
const stateResponse = await fetch(`${base}/api/state`);
if (!stateResponse.ok) throw new Error('State HTTP request failed');
const state = await stateResponse.json();
const page = await fetch(base);
if (!page.ok || !(await page.text()).includes('<title>Pi Durable')) throw new Error('UI HTTP request failed');
const link = process.env.PI_DATA_LINK;
if ((await statfs(link)).type !== 0x65735546) throw new Error('Not a FUSE mount');
const directory = join(link,process.env.PI_INSTANCE ?? 'pi-durable');
const markerPath = join(directory,'work','live-verification.txt');
if (mode === 'record') {
  let file;
  try { file = await open(markerPath,'wx',0o600); }
  catch (error) {
    if (error.code !== 'EEXIST') throw error;
    marker = await readFile(markerPath,'utf8');
    if (!marker.startsWith('pi-durable-live-')) throw new Error('Unexpected marker file');
  }
  if (file) { try { await file.writeFile(marker); await file.sync(); } finally { await file.close(); } }
}
const bytes = await readFile(markerPath);
if (bytes.toString() !== marker) throw new Error('Marker contents changed');
const files = await readdir(join(directory,'state'));
const sizes = await Promise.all(files.filter(name=>name.endsWith('.jsonl')).map(async name=>({name,bytes:(await stat(join(directory,'state',name))).size,sha256:createHash('sha256').update(await readFile(join(directory,'state',name))).digest('hex')})));
if (!sizes.some(file=>file.bytes > 0)) throw new Error('No non-empty JSONL state');
const main = await readFile(join(directory,'state','main.jsonl'));
const mainFile = {bytes:main.length,sha256:createHash('sha256').update(main).digest('hex')};
if (expectedMain) {
  if (main.length < expectedMain.bytes || createHash('sha256').update(main.subarray(0,expectedMain.bytes)).digest('hex') !== expectedMain.sha256) throw new Error('Prior JSONL commits changed or disappeared');
}
const pids = execFileSync('pgrep',['-f','^node /app/server.mjs$'],{encoding:'utf8'}).trim().split('\n');
console.log(JSON.stringify({rootId:state.id,marker,markerSha256:createHash('sha256').update(bytes).digest('hex'),health,httpUi:200,fuseType:'0x65735546',dataLink:link,stateFiles:sizes,mainFile,priorCommitsPreserved:expectedMain ? true : undefined,appPids:pids}));
'''.replace('MODE', json.dumps(args.mode)).replace('MARKER', json.dumps(marker)).replace('EXPECTED_MAIN',json.dumps(expected_main))
result = json.loads(run(['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15',
                         '-o', 'StrictHostKeyChecking=accept-new', '-o', 'IdentitiesOnly=yes',
                         '-o', 'IdentityAgent=none', '-i', str(Path(args.ssh_key).expanduser()),
                         '-p', str(ssh['port']), f"{ssh['user']}@{ssh['host']}",
                         'node --input-type=module -e ' + shlex.quote(script)]))
result.update(studioId=args.studio_id,workspace=args.workspace,image=studio['template']['repository'],
              studioUrl=studio['studioUrl'],checkedAt=datetime.now(timezone.utc).isoformat())
if args.mode == 'record':
    args.evidence.parent.mkdir(parents=True,exist_ok=True)
    args.evidence.write_text(json.dumps(result,indent=2)+'\n')
else:
    expected = json.loads(args.evidence.read_text())
    assert result['studioId'] == expected['studioId']
    assert result['image'] == expected['image']
    assert result['rootId'] == expected['rootId'], 'Harness root changed'
    assert result['markerSha256'] == expected['markerSha256'], 'Work file changed'
    result['restartPersistence'] = 'passed'
    args.evidence.with_name(args.evidence.stem+'-after-restart.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
