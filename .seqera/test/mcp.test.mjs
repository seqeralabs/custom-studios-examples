import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { once } from 'node:events';
import { mkdtemp, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { connectSeqeraMcp } from '../seqera-mcp.mjs';
import { openStudio } from '../server.mjs';
import { context } from '../storage.mjs';
import { createModels } from '@earendil-works/pi-ai/models';
import { fauxProvider, fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai/providers/faux';

async function mockMcp({ unauthorized = false } = {}) {
  const calls = [];
  const server = createServer(async (req,res) => {
    if (req.method !== 'POST') { res.writeHead(405); return res.end(); }
    assert.equal(req.headers.authorization,'Bearer test-mcp-secret');
    if (unauthorized) { res.writeHead(401); return res.end('test-mcp-secret'); }
    let raw=''; for await (const chunk of req) raw+=chunk;
    const input=JSON.parse(raw);
    if (input.id === undefined) { res.writeHead(202); return res.end(); }
    let result;
    if (input.method==='initialize') result={protocolVersion:'2025-03-26',capabilities:{tools:{}},serverInfo:{name:'mock-seqera',version:'1'}};
    else if (input.method==='tools/list') result=input.params?.cursor
      ? {tools:[{name:'call_seqera_api',inputSchema:{type:'object',properties:{path:{type:'string'}},required:['path']}}]}
      : {tools:[{name:'search_seqera_api',description:'Search API descriptions',inputSchema:{type:'object',properties:{query:{type:'string'}},required:['query']}}],nextCursor:'page-2'};
    else if (input.method==='tools/call') {
      calls.push(input.params);
      result={content:[{type:'text',text:'Workflow discovery succeeded'}],structuredContent:{found:true},isError:false};
    } else throw new Error(`Unexpected method: ${input.method}`);
    res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({jsonrpc:'2.0',id:input.id,result}));
  });
  server.listen(0,'127.0.0.1');await once(server,'listening');
  return {url:`http://127.0.0.1:${server.address().port}/mcp`,calls,close:()=>new Promise(resolve=>server.close(resolve))};
}

test('MCP is optional and authentication failures expose no credential', async () => {
  assert.equal((await connectSeqeraMcp({})).status().state,'not-configured');
  assert.equal((await connectSeqeraMcp({SEQERA_MCP_ENABLED:'0',SEQERA_MCP_TOKEN:'test-mcp-secret'})).status().state,'disabled');
  const remote=await mockMcp({unauthorized:true});
  try {
    const mcp=await connectSeqeraMcp({SEQERA_MCP_TOKEN:'test-mcp-secret'},{url:remote.url});
    assert.deepEqual(mcp.status(),{server:'seqera',state:'error',tools:[]});
    assert.doesNotMatch(JSON.stringify(mcp.status()),/test-mcp-secret/);
    await mcp.close();
  } finally {await remote.close();}
});

test('MCP tools execute through the durable harness and persist without replay', {timeout:15000}, async () => {
  const remote=await mockMcp();
  const link=await mkdtemp(join(tmpdir(),'pi-mcp-'));
  const env={PI_LOCAL_STORAGE:'1',PI_DATA_LINK:link,PI_MODEL:'mock-model',OPENAI_API_KEY:'faux',TOWER_ACCESS_TOKEN:'test-mcp-secret'};
  const models=createModels();
  const faux=fauxProvider({provider:'openai',models:[{id:'mock-model'}]});models.setProvider(faux.provider);
  faux.setResponses([
    fauxAssistantMessage(fauxToolCall('mcp__seqera__search_seqera_api',{query:'List workflows'},{id:'mcp-1'}),{stopReason:'toolUse'}),
    fauxAssistantMessage('Seqera discovery completed.'),
  ]);
  const connectMcp=async e=>{
    const mcp=await connectSeqeraMcp(e,{url:remote.url});
    assert.equal(mcp.extension.tools.length,2);
    assert.ok(mcp.extension.tools.every(t=>t.replay==='unsafe'));
    return mcp;
  };
  let studio;
  try {
    studio=await openStudio(env,{models,connectMcp});
    studio.server.listen(0,'127.0.0.1');await once(studio.server,'listening');
    const base=`http://127.0.0.1:${studio.server.address().port}`;
    assert.deepEqual((await (await fetch(`${base}/api/mcp`)).json()).tools,['mcp__seqera__search_seqera_api','mcp__seqera__call_seqera_api']);
    const response=await fetch(`${base}/api/submit`,{method:'POST',headers:{'X-Pi-Studio':'1','Content-Type':'application/json'},body:JSON.stringify({content:'List workflows',requestId:'seqera-demo'})});
    const submission=await response.json();
    assert.equal((await (await studio.harness.submission(submission.id,context)).wait(context)).status,'done');
    assert.deepEqual(remote.calls,[{name:'search_seqera_api',arguments:{query:'List workflows'}}]);
    await studio.close();
    studio=await openStudio(env,{models,connectMcp});
    const view=await studio.root.viewState(context);
    assert.match(JSON.stringify(view.value.entries),/Workflow discovery succeeded/);
    assert.match(JSON.stringify(view.value.entries),/Seqera discovery completed/);
    assert.doesNotMatch(JSON.stringify(view.value.entries),/test-mcp-secret/);
    view.dispose();
    const again=await studio.root.submit({type:'input',content:'List workflows',requestId:'seqera-demo'},context);
    assert.equal(again.id,submission.id);
    assert.equal(remote.calls.length,1);
  } finally {await studio?.close();await remote.close();await rm(link,{recursive:true,force:true});}
});
