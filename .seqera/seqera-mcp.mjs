import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import { defineExtension, defineTool } from '@earendil-works/pi-durable';

export const SEQERA_MCP_URL = 'https://mcp.seqera.io/mcp';

// Pi Durable does not load the coding agent's .pi/mcp.json extension.
export async function connectSeqeraMcp(env = process.env, options = {}) {
  const token = env.SEQERA_MCP_TOKEN ?? env.TOWER_ACCESS_TOKEN;
  let state = env.SEQERA_MCP_ENABLED === '0' ? 'disabled' : 'not-configured';
  let names = [];
  const status = () => ({ server: 'seqera', state, tools: names });
  if (state === 'disabled' || !token) return { status, async close() {} };
  const client = new Client({ name: 'pi-durable-studio', version: '1.0.0' });
  const transport = new StreamableHTTPClientTransport(new URL(options.url ?? SEQERA_MCP_URL), {
    requestInit: { headers: { Authorization: `Bearer ${token}` } },
    reconnectionOptions: { maxRetries: 0, initialReconnectionDelay: 1000, maxReconnectionDelay: 1000, reconnectionDelayGrowFactor: 1 },
  });
  try {
    await client.connect(transport, { timeout: 30000 });
    const tools = [];
    let cursor;
    do {
      const page = await client.listTools(cursor ? { cursor } : {}, { timeout: 30000 });
      tools.push(...page.tools);
      cursor = page.nextCursor;
    } while (cursor);
    names = tools.map(tool => `mcp__seqera__${tool.name.replace(/[^a-zA-Z0-9_]/g, '_')}`);
    if (new Set(names).size !== names.length) throw new Error('MCP tool names collide');
    const extension = defineExtension({
      name: 'seqera-mcp',
      tools: tools.map((tool, index) => defineTool({
        name: names[index],
        description: tool.description ?? tool.name,
        parameters: tool.inputSchema,
        // Even discovery is not automatically retried. MCP annotations are hints,
        // and generic call tools can perform writes as well as reads.
        replay: 'unsafe',
        async execute(args, _api, context) {
          try {
            const result = await client.callTool({ name: tool.name, arguments: args }, undefined,
              { timeout: 60000, signal: context.abortSignal });
            state = 'connected';
            const content = (result.content ?? []).map(block => ['text', 'image'].includes(block.type)
              ? block : { type: 'text', text: JSON.stringify(block) });
            return { content, isError: result.isError ?? false,
              ...(result.structuredContent ? { details: result.structuredContent } : {}) };
          } catch {
            state = 'error';
            // Transport errors may include headers. Never persist or log them.
            return { isError: true, content: [{ type: 'text', text: 'Seqera MCP request failed. Check the runtime token and network connection.' }] };
          }
        },
      })),
    });
    state = 'connected';
    return { extension, status, async close() { await client.close(); } };
  } catch {
    state = 'error';
    names = [];
    await client.close().catch(() => {});
    return { status, async close() {} };
  }
}
