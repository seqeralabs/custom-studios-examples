-- Seqera Studio actions for Rex. Paste into ~/.config/rex/init.lua, then run
-- `rex config reload`. Needs rex-studio on the PATH of your login shell.

local function shell_quote(s)
  return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

-- A login shell, so PATH and TOWER_ACCESS_TOKEN from your profile apply.
local function run_in_window(command)
  local shell = os.getenv("SHELL") or "/bin/sh"
  local w, err = rex.session.new_window {
    layout = rex.layout.block {
      flavor = "com.superlogical.terminal.shell",
      options = { command = { shell, "-lc", command .. '; exec "$SHELL" -l' } },
    },
  }
  if err ~= nil then error(err, 0) end
  return { window_id = w.window_id }
end

rex.action {
  name = "seqera_studio_new",
  title = "New Seqera Studio",
  category = "Seqera",
  keywords = "studio seqera cloud box",
  args = { name = "string?" },
  run = function(ctx, args)
    local command = "rex-studio new"
    if args.name ~= nil and args.name ~= "" then
      command = command .. " " .. shell_quote(args.name)
    end
    return run_in_window(command)
  end,
}

rex.action {
  name = "seqera_studio_ls",
  title = "List Seqera Studios",
  category = "Seqera",
  keywords = "studio seqera cloud box",
  run = function(ctx, args)
    return run_in_window("rex-studio ls")
  end,
}
