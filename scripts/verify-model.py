#!/usr/bin/env python3
"""Verify a real model/tool turn and compare its transcript after Studio restart.

submit makes one provider-backed request; record/verify make no provider requests.
Run submit once, then record/verify with verify-live.py around Studio stop/start.
"""
import argparse
import json
import hashlib
import shlex
import subprocess
from pathlib import Path
import uuid

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('mode', choices=['submit', 'record', 'verify'])
p.add_argument('--workspace', required=True)
p.add_argument('--studio-id', required=True)
p.add_argument('--ssh-key', required=True)
p.add_argument('--evidence', required=True, type=Path)
p.add_argument('--tw', default='tw')
a = p.parse_args()

def run(argv):
    r = subprocess.run(argv, capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(f"Command failed ({r.returncode}): {r.stderr.strip()}")
    return r.stdout

s = json.loads(run([a.tw, '-o', 'json', 'studios', 'view', '-w', a.workspace, '--id', a.studio_id]))['studio']
assert s['statusInfo']['status'] == 'running'
assert s['isPrivate']
expected = json.loads(a.evidence.read_text()) if a.mode != 'submit' else None
marker = expected['marker'] if expected else 'pi-model-proof-' + str(uuid.uuid4())
script = r'''
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
const mode = MODE, marker = MARKER, expected = EXPECTED;
const url = `http://127.0.0.1:${process.env.CONNECT_TOOL_PORT}`;
const path = join(process.env.PI_DATA_LINK,process.env.PI_INSTANCE ?? 'pi-durable','work','live-model-proof.txt');
if (mode === 'submit') {
  const r = await fetch(`${url}/api/submit`,{method:'POST',headers:{'Content-Type':'application/json','X-Pi-Studio':'1'},body:JSON.stringify({requestId:marker,content:`Use the write tool to create live-model-proof.txt in your working directory containing exactly ${marker} without a newline. Then reply with exactly: Saved ${marker}`})});
  if (r.status !== 202) throw new Error(`Submission failed: ${r.status}`);
}
let state;
for (let i=0;i<180;i++) {
  state = await (await fetch(`${url}/api/state`)).json();
  const entries = JSON.stringify(state.entries);
  let file; try {file = await readFile(path,'utf8');} catch {}
  const answered = state.entries.some(entry => entry.kind === 'pi.assistant' && (entry.model ?? []).some(message => (message.content ?? []).some(part => part.type === 'text' && part.text === `Saved ${marker}`)));
  if (file === marker && entries.includes('pi.tool-result') && answered) break;
  if (mode === 'verify') throw new Error('Prior answer or marker missing');
  if (i===179) throw new Error('Model/tool turn did not complete within 3 minutes');
  await new Promise(r=>setTimeout(r,1000));
}
const transcriptSha256 = createHash('sha256').update(JSON.stringify(state.entries)).digest('hex');
// Compare parsed entries in Python; replay can change JSON property order.
console.log(JSON.stringify({rootId:state.id,provider:state.provider,modelId:state.modelId,ready:state.ready,marker,toolFile:await readFile(path,'utf8'),entries:state.entries,transcriptSha256,modelToolTurn:'passed',restartTranscript:mode === 'verify' ? 'passed' : undefined}));
'''.replace('MODE',json.dumps(a.mode)).replace('MARKER',json.dumps(marker)).replace('EXPECTED',json.dumps({'transcriptSha256':expected['transcriptSha256']} if expected else None))
ssh = s['sshDetails']
r = json.loads(run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=15','-o','StrictHostKeyChecking=accept-new','-o','IdentitiesOnly=yes','-o','IdentityAgent=none','-i',str(Path(a.ssh_key).expanduser()),'-p',str(ssh['port']),f"{ssh['user']}@{ssh['host']}",'node --input-type=module -e '+shlex.quote(script)]))
r['canonicalTranscriptSha256'] = hashlib.sha256(json.dumps(r['entries'],sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
if expected:
    assert r['rootId'] == expected['rootId']
    if a.mode == 'verify':
        assert r['entries'] == expected['entries'], 'Transcript entries changed'
    else:
        assert r['entries'][:len(expected['entries'])] == expected['entries'], 'Prior entries changed'
output = a.evidence.with_name(a.evidence.stem+'-after-restart.json') if a.mode == 'verify' else a.evidence
output.write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps({k:v for k,v in r.items() if k != 'entries'},indent=2))
