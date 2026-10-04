#!/usr/bin/env python3
"""Read cloud objects through Data Explorer and compare live file hashes.

Run after the writing Studio reaches stopped. Needs TOWER_ACCESS_TOKEN.
No model requests or secret values are stored.
"""
import argparse
import hashlib
import json
import os
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--live-evidence', required=True, type=Path)
p.add_argument('--model-evidence', required=True, type=Path)
p.add_argument('--workspace-id', required=True)
p.add_argument('--data-link-id', required=True)
p.add_argument('--credentials-id', required=True)
p.add_argument('--instance', default='pi-durable')
p.add_argument('--api', default='https://api.cloud.seqera.io')
p.add_argument('--tw', default='tw')
p.add_argument('--output', required=True, type=Path)
a = p.parse_args()
live = json.loads(a.live_evidence.read_text())
model = json.loads(a.model_evidence.read_text())
s = json.loads(subprocess.run([a.tw,'-o','json','studios','view','-w',a.workspace_id,'--id',live['studioId']],capture_output=True,text=True,check=True).stdout)['studio']
assert s['statusInfo']['status'] == 'stopped', 'Wait for stopped before cloud comparison'
query = urllib.parse.urlencode({'workspaceId':a.workspace_id,'credentialsId':a.credentials_id})
files = [(f"{a.instance}/state/{f['name']}",f['sha256']) for f in live['stateFiles']]
files += [(f'{a.instance}/work/live-verification.txt',live['markerSha256']),
          (f'{a.instance}/work/live-model-proof.txt',hashlib.sha256(model['marker'].encode()).hexdigest())]
results = []
for path, expected in files:
    url = f"{a.api}/data-links/{a.data_link_id}/download/{urllib.parse.quote(path,safe='/')}?{query}"
    req = urllib.request.Request(url,headers={'Authorization':'Bearer '+os.environ['TOWER_ACCESS_TOKEN']})
    data = urllib.request.urlopen(req,timeout=60).read()
    actual = hashlib.sha256(data).hexdigest()
    assert actual == expected, f'Cloud bytes differ: {path}'
    results.append({'path':path,'bytes':len(data),'sha256':actual,'matchesLive':True})
result = {'studioId':live['studioId'],'cloudUploadMatchesLiveFiles':True,'files':results}
a.output.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
