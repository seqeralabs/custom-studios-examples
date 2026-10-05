// Read-only live check: authenticates, discovers tools and searches API metadata.
// Run with SEQERA_MCP_TOKEN or TOWER_ACCESS_TOKEN in the runtime environment.
import { connectSeqeraMcp } from '../.seqera/seqera-mcp.mjs';
import { context } from '../.seqera/storage.mjs';
const mcp = await connectSeqeraMcp();
try {
  if (mcp.status().state !== 'connected') throw new Error('Seqera MCP is not connected. Check the runtime token.');
  const search = mcp.extension.tools.find(tool => tool.name === 'mcp__seqera__search_seqera_api');
  if (!search) throw new Error('Seqera API discovery tool is unavailable');
  const result = await search.execute({ query: 'Find the API for listing workflows', limit: 1 }, {}, context);
  if (result.isError || !result.content?.some(block => block.type === 'text' && block.text.length > 0)) throw new Error('Seqera discovery call failed');
  console.log(JSON.stringify({ ...mcp.status(), discoveryCall: 'passed', replay: search.replay },null,2));
} finally { await mcp.close(); }
