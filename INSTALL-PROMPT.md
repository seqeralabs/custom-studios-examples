# Set up rex-studio

Paste everything below the line into a coding agent running on your computer.

---

Set up `rex-studio` on this computer. It creates Seqera Studios that run a Rex server and connects Rex on this computer to them over SSH.

Work through the steps in order. After each step, show me the command you ran and its full output. When a step says to wait for me, stop and wait until I say it is done. Do not do those steps yourself, and do not guess values I have not given you.

1. Install `rex-studio`:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/seqeralabs/custom-studios-examples/rex/install.sh | sh
   ```

   If it reports a missing tool, tell me the install hint it printed and wait for me to install it. If it warns that `~/.local/bin` is not on PATH, show me the line to add to my shell profile and wait for me to add it.

2. **Wait for me:** I need to add my SSH public key to my Seqera Platform user profile. Show me my public key (`cat ~/.ssh/id_ed25519.pub`, or another `~/.ssh/*.pub`). If I have none, tell me how to create one with `ssh-keygen -t ed25519`, but let me run it. Then wait while I add the key to my user profile in Seqera Platform.

3. **Wait for me:** I need to create an access token in my Seqera Platform user profile. Ask me to set it in my shell profile myself:

   ```bash
   export TOWER_ACCESS_TOKEN=<token>
   ```

   Do not ask me to paste the token into this chat. Once I say it is set, open a new shell, or source my profile, so the token is in your environment.

4. Run `rex-studio doctor` and show me the output. It checks the token, the tools, the workspace and the SSH key.

   - If the workspace line fails, list my workspaces from the error message. **Wait for me** to choose one, then ask me to add `export REX_STUDIO_WORKSPACE=<org>/<workspace>` to my shell profile, and run `rex-studio doctor` again.
   - If the SSH key line fails, go back to step 2.
   - If the token line fails, go back to step 3.

5. Create a Studio:

   ```bash
   rex-studio new
   ```

   This takes several minutes the first time, while the image builds. If it fails with "Unable to acquire AWS ECR authorization token", that workspace cannot build Git-based Studios. Tell me, and **wait for me** to pick another workspace.

   If it asks for a compute environment, show me the names it lists and **wait for me** to choose. Then run it again with `--compute-env <name>`.

6. List my Studios:

   ```bash
   rex-studio ls
   ```

   The new Studio should show status `running` and tunnel `up`.

7. Show me the commands:

   ```bash
   rex-studio help
   ```

8. Optional. Ask me whether I want **New Seqera Studio** and **List Seqera Studios** in the Rex command palette. If I do, show me the contents of `rex-actions.lua`:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/seqeralabs/custom-studios-examples/rex/rex-actions.lua
   ```

   **Wait for me** to paste it into `~/.config/rex/init.lua`. Do not edit that file yourself. Then run `rex config check` and `rex config reload`.

When you are done, summarize what was installed, the Studio name, its Rex host label, and how to reach it (`rex -S <label>`).
