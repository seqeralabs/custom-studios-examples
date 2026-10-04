import { writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { Harness, createRegistry, defineTask, defineExtension } from '@earendil-works/pi-durable';
import { createModels } from '@earendil-works/pi-ai/models';
import { openStorage, context } from '../storage.mjs';
const directory = process.argv[2];
const task = defineTask({
  name: 'test.checkpoint', version: 1, initial: () => ({ phase: 'first' }),
  phases: {
    first: async (_task, runtime, ctx) => runtime.commit(() => ({ status: 'pending', checkpoint: { phase: 'second', value: 42 } }), ctx),
    second: async (record, runtime, ctx) => {
      if (process.argv[3] === 'crash') {
        await writeFile(join(directory, 'checkpoint-ready'), 'ready');
        await runtime.sleep(Date.now() + 60000, ctx);
      }
      await runtime.commit(() => ({ status: 'terminal', outcome: { status: 'completed', result: record.state.checkpoint.value } }), ctx);
    },
  },
  abort: (_task, runtime, ctx) => runtime.commit(() => ({ status: 'terminal', outcome: { status: 'aborted' } }), ctx),
});
const registry = createRegistry();
registry.install(defineExtension({ name: 'test', tasks: [task] }));
const harness = await Harness.open(await openStorage(directory), { models: createModels(), registry }, context);
const root = await harness.root(context);
if (process.argv[3] === 'crash') {
  const submission = await root.submit({type:'write',entry:{kind:'test.note',data:'survives restart'},requestId:'note-1'},context);
  await submission.wait(context);
  const taskId = await root.commit(tx => tx.createTask(task, {}, { ownership: {kind:'conversation'} }), context);
  await writeFile(join(directory,'ids.json'), JSON.stringify({rootId:root.id,taskId,submissionId:submission.id}));
  harness.resume();
} else {
  const { readFile } = await import('node:fs/promises');
  const ids = JSON.parse(await readFile(join(directory,'ids.json'),'utf8'));
  harness.resume();
  const result = await harness.waitForTask(ids.taskId,context);
  const again = await root.submit({type:'write',entry:{kind:'test.note',data:'survives restart'},requestId:'note-1'},context);
  const view = await root.viewState(context);
  console.log(JSON.stringify({rootId:root.id,submissionId:again.id,result:result.state.outcome,notes:view.value.entries.filter(e => e.kind==='test.note').length}));
  view.dispose(); await harness.close(context);
}
