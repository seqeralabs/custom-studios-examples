import { mkdir, realpath, statfs, open, unlink } from 'node:fs/promises';
import { join, resolve, relative, isAbsolute } from 'node:path';
import { randomUUID } from 'node:crypto';
import { BACKGROUND_CONTEXT } from '@earendil-works/chord/context';
import { JsonlStorage } from '@earendil-works/pi-durable/storage/jsonl';
import { NodeExecutionEnv } from '@earendil-works/pi-durable/env/node';

export const context = BACKGROUND_CONTEXT;

export async function storagePaths(env = process.env) {
  if (!env.PI_DATA_LINK) throw new Error('Set PI_DATA_LINK to an existing writable data-link mount.');
  const link = await realpath(env.PI_DATA_LINK);
  if (env.PI_LOCAL_STORAGE !== '1') {
    const root = await realpath('/workspace/data');
    const inside = relative(root, link);
    if (!inside || inside.startsWith('..') || isAbsolute(inside)) {
      throw new Error('PI_DATA_LINK must be beneath /workspace/data.');
    }
    if ((await statfs(link)).type !== 0x65735546) {
      throw new Error('PI_DATA_LINK is not on a FUSE mount. Refusing ephemeral storage.');
    }
  }
  const name = env.PI_INSTANCE ?? 'pi-durable';
  if (!/^[a-zA-Z0-9_-]+$/.test(name)) throw new Error('PI_INSTANCE must contain only letters, numbers, _ or -.');
  const directory = join(link, name);
  const work = join(directory, 'work');
  await mkdir(work, { recursive: true });
  const probe = join(directory, `.probe-${randomUUID()}`);
  const file = await open(probe, 'wx', 0o600);
  try { await file.writeFile('pi-durable'); await file.sync(); }
  finally { await file.close(); await unlink(probe); }
  return { directory, work };
}

// Upstream fsync flushes sidecars but not the main commit marker. Flush every
// append before acknowledging it, including that marker.
class SyncedFileSystem extends NodeExecutionEnv {
  async appendFile(path, content, ctx) {
    const result = await super.appendFile(path, content, ctx);
    return result.ok ? this.flushFile(path, ctx) : result;
  }
}

export async function openStorage(directory) {
  return JsonlStorage.open(resolve(directory, 'state'),
    new SyncedFileSystem({ cwd: directory }), context, { fsync: true });
}
