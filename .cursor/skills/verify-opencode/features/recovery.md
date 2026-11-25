# Recovery

A user stops the writing instance, verifies saved state independently, and
opens the completed conversations and files from a fresh runtime.

## Sub-features

- `backup-stop`: normal stop confirms the final database backup and process exit.
- `snapshot-readback`: a separate reader copies saved bytes locally and checks SQLite plus stored transcript values.
- `fresh-restore`: a new container/Studio recovers complete messages and exact file bytes.
- `fusion-cloud`: live Fusion additionally requires independent cloud downloads and a fresh Studio without a parent checkpoint.

## How to get to it (user POV)

- Stop the local verification container, then open a fresh container on its volume.
- For Platform, stop the writing Studio and wait for stopped; download the saved objects through Data Explorer; start a fresh private Studio on the same data link/instance.
- Open Recent sessions and select the saved conversations. Ask for another native Read of the marker to verify continued operation.

## Driving it with control.py and browser control

Preconditions: use unsanitized exports only for synthetic fixtures; cloud paths below use the default `OPENCODE_INSTANCE=opencode` (adjust for a configured instance); doctor passes; completed file/MCP fixtures; all writer instances
known; source Studio stopped before a second Studio uses its instance.

- **Local lifecycle:** run `python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" recover`. It captures complete production exports, stops the owned writer, independently copies the saved DB/file with a read-only volume mount, opens SQLite only on the reader's local copy, compares stored messages, then launches a fresh container on the volume.
- **Fresh doctor:** require the helper's new doctor result before driving the restored UI. Use the new URL in `run.json`; the host port can change.
- **Browser reopen:** log in, choose the saved session in Recent sessions, expand the real tool results and confirm the completed answer. Save `recovery.png` and its accessibility snapshot. A new native Read after recovery is stronger proof of continued operation.
- **Live Fusion:** use an authorized private test Studio with a dedicated writable data link. Require `findmnt` reports `fuse.fusion`, actual image source hashes match, and completed model/tool turns. Stop it through Platform and wait for stopped. Download `opencode/state/opencode.db`, `opencode/work/verification-proof.txt` and the config through Data Explorer/Platform's data-link download route. Compare all message values and marker bytes, and run `PRAGMA quick_check` on the downloaded local DB. Create a fresh Studio with the same image/data link/instance and `parentCheckpoint: null`, then compare complete exports and file bytes and drive a new Read. Record source/fresh lifecycle status and evidence outside version control.
- **Proof scope:** local `recovery.json` proves the local backup mechanism. Live Fusion needs fresh cloud/lifecycle artifacts from this run; earlier chat evidence is context only. If no authorized workspace, data link, image or cloud access exists, record `verified-unreachable` with that prerequisite and the attempted Platform route; do not deploy to an invented workspace.

## Gotchas

- SQLite runs locally; never open the live SQLite DB on Fusion or open a read-only mounted WAL-mode snapshot without first copying it locally.
- Same-Studio root-filesystem checkpoints can mask a broken Fusion restore. A fresh Studio without a parent checkpoint removes that ambiguity.
- Only one Studio may write the instance. The wrapper's flock protects only the same host; it is not distributed exclusion.
- Fusion consolidates cloud objects when its writer stops. Running-instance cache reads, fsync, Docker volumes and image builds are not independent cloud evidence.
- Normal-stop recovery does not establish abrupt host-loss safety or replay of an interrupted model request.
- Clean up only test resources this run created, after retaining evidence; never delete checkpoint objects directly.
