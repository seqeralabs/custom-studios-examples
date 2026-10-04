import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { Harness, createRegistry } from '@earendil-works/pi-durable';
import { CodingTools } from '@earendil-works/pi-durable/tools';
import { NodeExecutionEnv } from '@earendil-works/pi-durable/env/node';
import { createModels } from '@earendil-works/pi-ai/models';
import { openaiProvider } from '@earendil-works/pi-ai/providers/openai';
import { openrouterProvider } from '@earendil-works/pi-ai/providers/openrouter';
import { anthropicProvider } from '@earendil-works/pi-ai/providers/anthropic';
import { context, storagePaths, openStorage } from './storage.mjs';

export async function openStudio(env = process.env, options = {}) {
  const paths = await storagePaths(env);
  const provider = env.PI_PROVIDER ?? 'openai';
  const providers = { openai: [openaiProvider, 'OPENAI_API_KEY'], anthropic: [anthropicProvider, 'ANTHROPIC_API_KEY'], openrouter: [openrouterProvider, 'OPENROUTER_API_KEY'] };
  if (!Object.hasOwn(providers, provider)) throw new Error('PI_PROVIDER must be openai, anthropic or openrouter.');
  const [providerFactory, keyVariable] = providers[provider];
  const modelId = env.PI_MODEL;
  if (!modelId) throw new Error('Set PI_MODEL to a model supported by your provider.');
  const ready = Boolean(env[keyVariable]);
  const models = options.models ?? createModels();
  if (!options.models) models.setProvider(providerFactory());
  if (!models.getModel(provider, modelId)) throw new Error('PI_MODEL is not in the pinned provider catalog.');
  const registry = createRegistry();
  registry.install(CodingTools);
  const harness = await Harness.open(await openStorage(paths.directory), {
    models, registry,
    env: ({ cwd }) => new NodeExecutionEnv({ cwd: cwd ?? paths.work }),
    settings: { retry: { maxRetries: 2 } },
  }, context);
  const root = await harness.root(context, { agent: {
    model: { provider, modelId }, cwd: paths.work,
    instructions: 'You are an assistant working in a Seqera Studio. Keep project files in your working directory. Do not modify the harness storage or credentials.',
  } });
  // Apply explicit launch configuration to an existing conversation too.
  await root.configure({ model: { provider, modelId }, cwd: paths.work }, context);
  if (ready) harness.resume();
  const view = await root.viewState(context);
  const html = await readFile(new URL('./index.html', import.meta.url));
  let closing = false;
  const server = createServer(async (req, res) => {
    const json = (status, value) => { res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(value)); };
    try {
      if (closing) return json(503, { error: 'Studio is stopping' });
      const path = new URL(req.url, 'http://localhost').pathname;
      if (req.method === 'GET' && path === '/') {
        res.writeHead(200, { 'Content-Type': 'text/html', 'Cache-Control': 'no-store', 'Content-Security-Policy': "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'" });
        return res.end(html);
      }
      if (req.method === 'GET' && path === '/healthz') return json(200, { ok: true, ready, storage: 'jsonl' });
      if (req.method === 'GET' && path === '/api/state') return json(200, { id: root.id, provider, modelId, ready, ...view.value });
      if (req.method !== 'POST' || !['/api/submit', '/api/abort'].includes(path)) return json(404, { error: 'Not found' });
      // A cross-origin form cannot set this header; no CORS headers are granted.
      if (req.headers['x-pi-studio'] !== '1' || req.headers['content-type'] !== 'application/json') return json(403, { error: 'Use the Studio client' });
      if (!ready) return json(503, { error: 'Configure the provider API key in the Studio environment and restart.' });
      let body = '';
      for await (const chunk of req) {
        body += chunk;
        if (Buffer.byteLength(body) > 65536) return json(413, { error: 'Message too large' });
      }
      const input = JSON.parse(body);
      if (path === '/api/abort') {
        await root.abort(context);
        return json(200, { ok: true });
      }
      if (typeof input.content !== 'string' || !input.content.trim() ||
          typeof input.requestId !== 'string' || input.requestId.length > 128 || !input.requestId ||
          !['followUp', 'steer'].includes(input.whenBusy ?? 'followUp')) return json(400, { error: 'Provide content, requestId and a valid queue mode.' });
      const submission = await root.submit({ type: 'input', content: input.content,
        requestId: input.requestId, whenBusy: input.whenBusy ?? 'followUp' }, context);
      return json(202, { id: submission.id });
    } catch (error) {
      if (error instanceof SyntaxError) return json(400, { error: 'Invalid JSON' });
      console.error(error);
      json(500, { error: 'Request failed; inspect the Studio logs.' });
    }
  });
  return { server, harness, root, async close() {
    closing = true;
    server.close();
    server.closeIdleConnections();
    view.dispose();
    // close preserves unfinished tasks for resume; abort would cancel them.
    await harness.close(context);
    server.closeAllConnections();
  } };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const studio = await openStudio();
  const port = Number(process.env.CONNECT_TOOL_PORT ?? 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid CONNECT_TOOL_PORT');
  studio.server.listen(port, '0.0.0.0', () => console.log(`Pi Durable listening on ${port}`));
  let stopping = false;
  for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, async () => {
    if (stopping) return;
    stopping = true;
    const timeout = setTimeout(() => process.exit(1), 25000);
    try { await studio.close(); clearTimeout(timeout); process.exit(0); }
    catch (error) { console.error(error); process.exit(1); }
  });
}
