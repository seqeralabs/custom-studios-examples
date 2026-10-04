import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, access, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { storagePaths } from '../storage.mjs';
import { openStudio } from '../server.mjs';

async function waitForFile(path) {
  for (let i=0;i<200;i++) {
    try { await access(path); return; } catch {}
    await new Promise(resolve=>setTimeout(resolve,50));
  }
  throw new Error('Checkpoint was not reached');
}

test('refuses absent or non-Fusion storage and invalid instance names', async () => {
  await assert.rejects(storagePaths({}), /PI_DATA_LINK/);
  await assert.rejects(storagePaths({PI_DATA_LINK:tmpdir()}));
  await assert.rejects(storagePaths({PI_DATA_LINK:tmpdir(),PI_LOCAL_STORAGE:'1',PI_INSTANCE:'../escape'}), /PI_INSTANCE/);
});

test('HTTP starts, protects writes, and preserves the root across shutdown', async () => {
  const link = await mkdtemp(join(tmpdir(),'pi-http-'));
  const env = {PI_DATA_LINK:link,PI_LOCAL_STORAGE:'1',PI_MODEL:'gpt-6.1-sol'};
  let studio;
  try {
    studio = await openStudio(env);
    studio.server.listen(0,'127.0.0.1'); await once(studio.server,'listening');
    const url = `http://127.0.0.1:${studio.server.address().port}`;
    assert.equal((await fetch(url)).status,200);
    assert.deepEqual(await (await fetch(`${url}/healthz`)).json(),{ok:true,ready:false,storage:'jsonl'});
    assert.equal((await fetch(`${url}/api/submit`,{method:'POST',body:'{}'})).status,403);
    assert.equal((await fetch(`${url}/api/submit`,{method:'POST',headers:{'X-Pi-Studio':'1','Content-Type':'application/json'},body:'{}'})).status,503);
    const id = (await (await fetch(`${url}/api/state`)).json()).id;
    await studio.close();
    studio = await openStudio(env);
    assert.equal(studio.root.id,id);
  } finally { await studio?.close(); await rm(link,{recursive:true,force:true}); }
});

test('SIGKILL recovery resumes a checkpoint and deduplicates a submission', {timeout:20000}, async () => {
  const directory = await mkdtemp(join(tmpdir(),'pi-recovery-'));
  const worker = new URL('./recovery-worker.mjs',import.meta.url);
  let child;
  try {
    child = spawn(process.execPath,[worker.pathname,directory,'crash'],{stdio:['ignore','pipe','pipe']});
    let errors=''; child.stderr.on('data',chunk=>errors+=chunk);
    await waitForFile(join(directory,'checkpoint-ready')).catch(error=>{throw new Error(`${error.message}: ${errors}`)});
    const stopped = once(child,'exit'); child.kill('SIGKILL'); await stopped;
    const ids = JSON.parse(await readFile(join(directory,'ids.json'),'utf8'));
    child = spawn(process.execPath,[worker.pathname,directory,'resume'],{stdio:['ignore','pipe','pipe']});
    let output=''; errors='';
    child.stdout.on('data',chunk=>output+=chunk); child.stderr.on('data',chunk=>errors+=chunk);
    const [code] = await once(child,'exit'); assert.equal(code,0,errors);
    const result = JSON.parse(output.trim());
    assert.equal(result.rootId,ids.rootId);
    assert.equal(result.submissionId,ids.submissionId);
    assert.equal(result.notes,1);
    assert.deepEqual(result.result,{status:'completed',result:42});
  } finally { child?.kill('SIGKILL'); await rm(directory,{recursive:true,force:true}); }
});

test('HTTP submission executes a tool and keeps the answer after reopening', {timeout:10000}, async () => {
  const { createModels } = await import('@earendil-works/pi-ai/models');
  const { fauxProvider, fauxAssistantMessage, fauxToolCall } = await import('@earendil-works/pi-ai/providers/faux');
  const { context } = await import('../storage.mjs');
  const link = await mkdtemp(join(tmpdir(),'pi-chat-'));
  const models = createModels();
  const faux = fauxProvider({provider:'openai',models:[{id:'test-model'}]});
  models.setProvider(faux.provider);
  faux.setResponses([
    fauxAssistantMessage(fauxToolCall('write',{path:'marker.txt',content:'persistent marker'},{id:'write-1'}),{stopReason:'toolUse'}),
    fauxAssistantMessage('The marker is saved.'),
  ]);
  const env = {PI_DATA_LINK:link,PI_LOCAL_STORAGE:'1',PI_MODEL:'test-model',OPENAI_API_KEY:'faux-not-a-key'};
  let studio;
  try {
    studio = await openStudio(env,{models});
    studio.server.listen(0,'127.0.0.1'); await once(studio.server,'listening');
    const url = `http://127.0.0.1:${studio.server.address().port}`;
    const options = {method:'POST',headers:{'X-Pi-Studio':'1','Content-Type':'application/json'},body:JSON.stringify({content:'Write a marker',requestId:'chat-1'})};
    const response = await fetch(`${url}/api/submit`,options);
    assert.equal(response.status,202);
    const submission = await response.json();
    const settled = await (await studio.harness.submission(submission.id,context)).wait(context);
    assert.equal(settled.status,'done');
    assert.equal(await readFile(join(link,'pi-durable','work','marker.txt'),'utf8'),'persistent marker');
    const id = studio.root.id;
    await studio.close();
    studio = await openStudio(env,{models});
    assert.equal(studio.root.id,id);
    const view = await studio.root.viewState(context);
    assert.match(JSON.stringify(view.value.entries),/The marker is saved/);
    assert.match(JSON.stringify(view.value.entries),/pi.tool-result/);
    const again = await studio.root.submit({type:'input',content:'Write a marker',requestId:'chat-1'},context);
    assert.equal(again.id,submission.id);
    assert.equal(faux.state.callCount,2);
    view.dispose();
  } finally { await studio?.close(); await rm(link,{recursive:true,force:true}); }
});

test('OpenRouter uses its own credential variable and provider catalog', async () => {
  const link = await mkdtemp(join(tmpdir(),'pi-openrouter-'));
  let studio;
  try {
    studio = await openStudio({PI_DATA_LINK:link,PI_LOCAL_STORAGE:'1',PI_PROVIDER:'openrouter',PI_MODEL:'openai/gpt-6.1-sol',OPENAI_API_KEY:'wrong-provider'});
    studio.server.listen(0,'127.0.0.1'); await once(studio.server,'listening');
    const state = await (await fetch(`http://127.0.0.1:${studio.server.address().port}/api/state`)).json();
    assert.equal(state.provider,'openrouter');
    assert.equal(state.modelId,'openai/gpt-6.1-sol');
    assert.equal(state.ready,false);
  } finally { await studio?.close(); await rm(link,{recursive:true,force:true}); }
});
