#!/usr/bin/env bats
# Behavior tests for bin/rex-studio. curl, ssh, launchctl, systemctl, rex,
# open, sleep and uname are PATH stubs that log their argv to $STUB_LOG.

setup() {
  BIN=$BATS_TEST_DIRNAME/../bin/rex-studio
  export STUB_LOG=$BATS_TEST_TMPDIR/calls.log
  export STUB_STATE=$BATS_TEST_TMPDIR/state
  export FIXTURES=$BATS_TEST_TMPDIR/fixtures
  mkdir -p "$STUB_STATE" "$FIXTURES"
  : >"$STUB_LOG"
  export PATH=$BATS_TEST_DIRNAME/stubs:$PATH
  export HOME=$BATS_TEST_TMPDIR/home
  mkdir -p "$HOME"
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/st ate"
  export XDG_CONFIG_HOME=$HOME/.config
  export TOWER_ACCESS_TOKEN=test-token
  export TOWER_API_ENDPOINT=https://api.test
  export REX_STUDIO_WORKSPACE=acme/research
  unset SEQERA_ACCESS_TOKEN REX_STUDIO_COMPUTE_ENV REX_STUDIO_REPO REX_STUDIO_REVISION REX_STUDIO_PORT_BASE STUB_OS

  # The tunnel port is 20000 + (POSIX cksum of the sessionId) mod 10000.
  # Studio 306 hashes to the same port as 6afaa755.
  PORT=24329
  ENDPOINT=http://127.0.0.1:$PORT
  PLIST=$HOME/Library/LaunchAgents/io.seqera.rex-studio.a6afaa755.plist

  fixture GET /user-info '{"user":{"id":42,"userName":"edmund"}}'
  fixture GET /user/42/workspaces '{"orgsAndWorkspaces":[
    {"orgName":"acme","workspaceName":null,"workspaceId":null},
    {"orgName":"acme","workspaceName":"research","workspaceId":100},
    {"orgName":"acme","workspaceName":"other","workspaceId":200}]}'
  fixture GET '/studios?workspaceId=200&max=100&offset=0' '{"studios":[]}'
  fixture GET '/compute-envs?workspaceId=100&status=AVAILABLE' '{"computeEnvs":[
    {"id":"ce-batch","name":"aws-batch","platform":"aws-batch"},
    {"id":"ce-studio","name":"Studios-CE","platform":"aws-batch"}]}'
}

teardown() {
  if [[ -n ${LISTENER:-} ]]; then kill "$LISTENER" 2>/dev/null || true; fi
}

listen_on() {
  python3 -c 'import socket, sys, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", int(sys.argv[1])))
s.listen()
open(sys.argv[2], "w").close()
time.sleep(60)' "$1" "$BATS_TEST_TMPDIR/listening" >/dev/null 2>&1 3>&- &
  LISTENER=$!
  disown "$LISTENER"
  for _ in $(seq 50); do
    [[ -e $BATS_TEST_TMPDIR/listening ]] && return 0
    command sleep 0.1
  done
  return 1
}

plist_forward() {
  grep -o '<string>127\.0\.0\.1:[0-9]*:127\.0\.0\.1:7297</string>' "$1" | sed 's/<string>127.0.0.1:\([0-9]*\):.*/\1/'
}

# bash ignores a failing "! cmd" under set -e, so negations go through here.
refute() {
  if "$@"; then
    echo "expected to fail: $*" >&2
    return 1
  fi
}

key() {
  printf '%s %s' "$1" "$2" | tr -c 'A-Za-z0-9' '_'
}

fixture() {
  printf '%s\n' "$3" >"$FIXTURES/$(key "$1" "$2")"
}

fixture_seq() {
  local dir i=1 body
  dir=$FIXTURES/$(key "$1" "$2")
  mkdir -p "$dir"
  shift 2
  for body in "$@"; do
    printf '%s\n' "$body" >"$dir/$i"
    i=$((i + 1))
  done
}

# studio ID NAME STATUS [REVISION] [OWNER] [MESSAGE]
studio() {
  jq -nc --arg id "$1" --arg name "$2" --arg status "$3" --arg rev "${4:-rex}" \
    --argjson owner "${5:-42}" --arg msg "${6:-}" '{
      sessionId: $id, name: $name, workspaceId: 100,
      user: {id: $owner},
      statusInfo: {status: $status, message: $msg},
      remoteConfig: {repository: "https://github.com/seqeralabs/custom-studios-examples", revision: $rev},
      configuration: {sshEnabled: true},
      sshDetails: {host: "connect.cloud.seqera.io", port: 2222, user: ("edmund@a" + $id)}
    }'
}

studios_in_research() {
  fixture GET '/studios?workspaceId=100&max=100&offset=0' "$(jq -sc '{studios: .}' <<<"$*")"
}

rex_host_endpoints() {
  jq -r --arg l "$1" '.hosts[].host | select(.label == $l) | .endpoints[]' "$STUB_STATE/rex-hosts.json"
}

@test "new creates an SSH-enabled Studio from the rex branch and wires a Rex host and session" {
  fixture POST '/studios?workspaceId=100&autoStart=true' '{"studio":{"sessionId":"6afaa755"}}'
  fixture_seq GET '/studios/6afaa755?workspaceId=100' \
    "$(studio 6afaa755 demo building | jq -c '.waveBuildUrl = "https://wave.test/b/1"')" \
    "$(studio 6afaa755 demo starting)" \
    "$(studio 6afaa755 demo running)"

  run "$BIN" new demo
  [ "$status" -eq 0 ]

  body=$(grep '^curl POST /studios?workspaceId=100&autoStart=true ' "$STUB_LOG" | cut -d' ' -f4-)
  [ "$(jq -c . <<<"$body")" = "$(jq -nc '{
    name: "demo", description: "Rex Studio created by rex-studio", computeEnvId: "ce-studio",
    remoteConfig: {repository: "https://github.com/seqeralabs/custom-studios-examples", revision: "rex"},
    configuration: {lifespanHours: 12, sshEnabled: true}, isPrivate: true}')" ]

  [[ $output == *"https://wave.test/b/1"* ]]
  grep -qF "<string>127.0.0.1:$PORT:127.0.0.1:7297</string>" "$PLIST"
  grep -qF '<string>edmund@a6afaa755@connect.cloud.seqera.io</string>' "$PLIST"
  grep -qF '<string>2222</string>' "$PLIST"
  grep -qxF 'io.seqera.rex-studio.a6afaa755' "$STUB_STATE/launchd-loaded"
  [ "$(rex_host_endpoints studio-demo)" = "$ENDPOINT" ]
  grep -qF 'rex -S studio-demo new demo' "$STUB_LOG"
  [[ $output == *"rex -S studio-demo"* ]]
  [[ $output == *"ssh -p 2222 edmund@a6afaa755@connect.cloud.seqera.io"* ]]
  [[ $output == *"Add Remote Host"*"$ENDPOINT"* ]]
  refute grep -q '^open' "$STUB_LOG"
}

@test "new --no-session leaves Rex sessions alone and honours the flags" {
  fixture GET '/compute-envs?workspaceId=200&status=AVAILABLE' '{"computeEnvs":[{"id":"ce-x","name":"gpu","platform":"aws-batch"}]}'
  fixture POST '/studios?workspaceId=200&autoStart=true' '{"studio":{"sessionId":"77"}}'
  fixture GET '/studios/77?workspaceId=200' "$(studio 77 box running)"

  run "$BIN" new box --workspace acme/other --compute-env gpu --lifespan 3 --no-session
  [ "$status" -eq 0 ]
  body=$(grep '^curl POST ' "$STUB_LOG" | cut -d' ' -f4-)
  [ "$(jq -r '.computeEnvId, .configuration.lifespanHours' <<<"$body" | paste -sd, -)" = "ce-x,3" ]
  refute grep -q ' new box' "$STUB_LOG"
}

@test "new fails fast on a failed build, shows the message, and sets up nothing" {
  fixture POST '/studios?workspaceId=100&autoStart=true' '{"studio":{"sessionId":"6afaa755"}}'
  fixture_seq GET '/studios/6afaa755?workspaceId=100' \
    "$(studio 6afaa755 demo buildFailed rex 42 'Unable to acquire AWS ECR authorization token')" \
    "$(studio 6afaa755 demo running)"

  run "$BIN" new demo
  [ "$status" -ne 0 ]
  [[ $output == *"Unable to acquire AWS ECR authorization token"* ]]
  [[ $output == *"--workspace"* ]]
  [ ! -e "$PLIST" ]
  refute grep -q 'hosts add' "$STUB_LOG"
}

@test "new refuses to guess between compute environments" {
  fixture GET '/compute-envs?workspaceId=100&status=AVAILABLE' '{"computeEnvs":[
    {"id":"a","name":"studio-one"},{"id":"b","name":"studio-two"}]}'

  run "$BIN" new demo
  [ "$status" -ne 0 ]
  [[ $output == *"studio-one"* && $output == *"studio-two"* ]]
  refute grep -q '^curl POST' "$STUB_LOG"
}

@test "new rejects a workspace that is not visible and a bad lifespan before creating anything" {
  run "$BIN" new demo --workspace acme/nope
  [ "$status" -ne 0 ]
  [[ $output == *"acme/research"* ]]

  run "$BIN" new demo --lifespan soon
  [ "$status" -ne 0 ]
  refute grep -q '^curl POST' "$STUB_LOG"
}

@test "rex calls do not inherit REX_BLOCK or REX_SESSION" {
  studios_in_research "$(studio 6afaa755 demo running)"
  export REX_BLOCK=block:1 REX_SESSION=session:1

  run "$BIN" sync
  [ "$status" -eq 0 ]
  grep -q '^rex ' "$STUB_LOG"
  refute grep -qE 'REX_BLOCK=block|REX_SESSION=session' "$STUB_LOG"
}

@test "sync converges: a second run changes nothing" {
  studios_in_research "$(studio 6afaa755 demo running)"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  first_plist=$(cat "$PLIST")
  first_hosts=$(cat "$STUB_STATE/rex-hosts.json")
  : >"$STUB_LOG"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  [ "$(cat "$PLIST")" = "$first_plist" ]
  [ "$(cat "$STUB_STATE/rex-hosts.json")" = "$first_hosts" ]
  refute grep -qE 'launchctl (bootstrap|bootout)|rex hosts (add|edit|remove)' "$STUB_LOG"
}

@test "sync leaves my SSH Studios from other revisions alone" {
  studios_in_research "$(studio 6afaa755 demo running)" "$(studio 9000 notebook running main)"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB_STATE/launchd-loaded")" = 'io.seqera.rex-studio.a6afaa755' ]
  [ "$(jq -r '[.hosts[].host.label] | join(",")' "$STUB_STATE/rex-hosts.json")" = 'studio-demo' ]
  [ ! -e "$XDG_STATE_HOME/rex-studio/a9000.port" ]
}

@test "a long Studio name gets a unique Rex label of at most 64 characters" {
  long=gradient-4791ec1b-lilly-splicing-rosalind-20260923092653-extra-long
  studios_in_research "$(studio 6afaa755 "$long" running)" "$(studio 7bbbbbbb "$long" running)"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  labels=$(jq -r '.hosts[].host.label' "$STUB_STATE/rex-hosts.json")
  [ "$(wc -l <<<"$labels")" -eq 2 ]
  [ "$(awk '{ if (length($0) > 64) bad = 1 } END { print bad + 0 }' <<<"$labels")" = 0 ]
  grep -qx 'studio-.*-6afaa755' <<<"$labels"
  grep -qx 'studio-.*-7bbbbbbb' <<<"$labels"
}

@test "sync reloads an agent whose plist survived but is not loaded" {
  studios_in_research "$(studio 6afaa755 demo running)"
  run "$BIN" sync
  : >"$STUB_STATE/launchd-loaded"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  grep -qxF 'io.seqera.rex-studio.a6afaa755' "$STUB_STATE/launchd-loaded"
}

@test "sync will not take over a Rex host label used for something else" {
  studios_in_research "$(studio 6afaa755 demo running)"
  echo '{"hosts":[{"host":{"label":"Studio-Demo","endpoints":["http://127.0.0.1:1"]}}]}' >"$STUB_STATE/rex-hosts.json"

  run "$BIN" sync
  [ "$status" -ne 0 ]
  [ "$(rex_host_endpoints Studio-Demo)" = "http://127.0.0.1:1" ]
}

@test "sync stops the tunnel of a stopped Studio but keeps its Rex host" {
  studios_in_research "$(studio 6afaa755 demo running)"
  run "$BIN" sync
  studios_in_research "$(studio 6afaa755 demo stopped)"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  [ ! -e "$PLIST" ]
  refute grep -qxF 'io.seqera.rex-studio.a6afaa755' "$STUB_STATE/launchd-loaded"
  [ "$(rex_host_endpoints studio-demo)" = "$ENDPOINT" ]
}

@test "sync removes agent and host of a deleted Studio and leaves other loopback hosts alone" {
  studios_in_research "$(studio 6afaa755 demo running)"
  run "$BIN" sync
  jq '.hosts += [{host: {label: "studio", endpoints: ["http://127.0.0.1:17297"]}},
                 {host: {label: "studio-local", endpoints: ["http://127.0.0.1:17298"]}}]' \
    "$STUB_STATE/rex-hosts.json" >"$STUB_STATE/h" && mv "$STUB_STATE/h" "$STUB_STATE/rex-hosts.json"
  studios_in_research

  run "$BIN" sync
  [ "$status" -eq 0 ]
  [ ! -e "$PLIST" ]
  [ -z "$(rex_host_endpoints studio-demo)" ]
  [ "$(rex_host_endpoints studio)" = "http://127.0.0.1:17297" ]
  [ "$(rex_host_endpoints studio-local)" = "http://127.0.0.1:17298" ]

  : >"$STUB_LOG"
  run "$BIN" sync
  [ "$status" -eq 0 ]
  refute grep -qE 'launchctl (bootstrap|bootout)|rex hosts (add|edit|remove)' "$STUB_LOG"
}

@test "a Studio whose port is held by another host or Studio gets the next free one" {
  studios_in_research "$(studio 6afaa755 demo running)" "$(studio 306 twin running)"
  echo '{"hosts":[{"host":{"label":"studio-old","endpoints":["http://127.0.0.1:'"$PORT"'"]}}]}' >"$STUB_STATE/rex-hosts.json"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  [ "$(rex_host_endpoints studio-old)" = "$ENDPOINT" ]
  ports=$(printf '%s\n' "$(rex_host_endpoints studio-demo)" "$(rex_host_endpoints studio-twin)" | sort)
  [ "$ports" = "$(printf 'http://127.0.0.1:%s\n' $((PORT + 1)) $((PORT + 2)))" ]
  [ "$(plist_forward "$PLIST")" = "$(rex_host_endpoints studio-demo | sed 's/.*://')" ]
  [ "$(plist_forward "$HOME/Library/LaunchAgents/io.seqera.rex-studio.a306.plist")" = "$(rex_host_endpoints studio-twin | sed 's/.*://')" ]
}

@test "a Studio keeps the port its Rex host already has" {
  studios_in_research "$(studio 6afaa755 demo running)"
  echo '{"hosts":[{"host":{"label":"studio-demo","endpoints":["http://127.0.0.1:25000/"]}}]}' >"$STUB_STATE/rex-hosts.json"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  [ "$(plist_forward "$PLIST")" = 25000 ]
  refute grep -qE 'rex hosts (add|edit|remove)' "$STUB_LOG"
}

@test "REX_STUDIO_PORT_BASE moves the port range and must be a usable port" {
  studios_in_research "$(studio 6afaa755 demo running)"

  REX_STUDIO_PORT_BASE=30000 run "$BIN" sync
  [ "$status" -eq 0 ]
  [ "$(rex_host_endpoints studio-demo)" = "http://127.0.0.1:34329" ]

  REX_STUDIO_PORT_BASE=60000 run "$BIN" ls
  [ "$status" -ne 0 ]
  [[ $output == *REX_STUDIO_PORT_BASE* ]]
}

@test "sync keeps local resources when a workspace cannot be listed" {
  studios_in_research "$(studio 6afaa755 demo running)"
  run "$BIN" sync
  rm "$FIXTURES/$(key GET '/studios?workspaceId=100&max=100&offset=0')"

  run "$BIN" sync
  [ -e "$PLIST" ]
  [ -n "$(rex_host_endpoints studio-demo)" ]
}

@test "ls shows only my Studios from the rex branch, with tunnel state" {
  studios_in_research "$(studio 6afaa755 demo running)" "$(studio 111 stopped-one stopped)" \
    "$(studio 222 theirs running rex 7)" "$(studio 333 notebook running main)"
  run "$BIN" sync
  listen_on "$PORT"

  run "$BIN" ls
  [ "$status" -eq 0 ]
  [ "$(awk '{print $1, $2, $3, $4, $5}' <<<"$output")" = "$(printf '%s\n' \
    'NAME STATUS WORKSPACE TUNNEL HOST' \
    'demo running acme/research up studio-demo' \
    'stopped-one stopped acme/research - studio-stopped-one')" ]

  run "$BIN" ls --all --json
  [ "$(jq -r 'map(.name) | sort | join(",")' <<<"$output")" = "demo,notebook,stopped-one" ]
  [ "$(jq -r '.[] | select(.name == "notebook") | .tunnel' <<<"$output")" = "down" ]
}

@test "rm without --yes and without a terminal deletes nothing" {
  studios_in_research "$(studio 6afaa755 demo running)"

  run "$BIN" rm demo </dev/null
  [ "$status" -ne 0 ]
  refute grep -q '^curl DELETE' "$STUB_LOG"
}

@test "rm will not take a piped yes as confirmation" {
  studios_in_research "$(studio 6afaa755 demo running)"

  run bash -c "printf 'y\\n' | '$BIN' rm demo"
  [ "$status" -ne 0 ]
  refute grep -q '^curl DELETE' "$STUB_LOG"
}

@test "rm --yes stops a running Studio, deletes it once stopped, and removes its local resources" {
  studios_in_research "$(studio 6afaa755 demo running)"
  run "$BIN" sync
  fixture PUT '/studios/6afaa755/stop?workspaceId=100' '{}'
  fixture_seq GET '/studios/6afaa755?workspaceId=100' \
    "$(studio 6afaa755 demo running)" "$(studio 6afaa755 demo stopping)" "$(studio 6afaa755 demo stopped)"
  fixture DELETE '/studios/6afaa755?workspaceId=100' ''
  : >"$XDG_STATE_HOME/rex-studio/a6afaa755.log"
  : >"$STUB_LOG"

  run "$BIN" rm a6afaa755 --yes
  [ "$status" -eq 0 ]
  [ "$(grep -E '^curl (PUT|DELETE)' "$STUB_LOG" | cut -d' ' -f2)" = "$(printf 'PUT\nDELETE')" ]
  [ "$(sed -n '/^curl DELETE/q;/^curl GET \/studios\/6afaa755/p' "$STUB_LOG" | wc -l)" -ge 3 ]
  [ ! -e "$PLIST" ]
  [ -z "$(rex_host_endpoints studio-demo)" ]
  [ ! -e "$XDG_STATE_HOME/rex-studio/a6afaa755.port" ]
  [ ! -e "$XDG_STATE_HOME/rex-studio/a6afaa755.log" ]
}

@test "rm deletes a stopped or failed Studio without stopping it" {
  studios_in_research "$(studio 6afaa755 demo stopped)" "$(studio 306 broken buildFailed)"
  fixture DELETE '/studios/6afaa755?workspaceId=100' ''
  fixture DELETE '/studios/306?workspaceId=100' ''

  run "$BIN" rm demo --yes
  [ "$status" -eq 0 ]
  run "$BIN" rm broken --yes
  [ "$status" -eq 0 ]
  refute grep -q '^curl PUT' "$STUB_LOG"
  [ "$(grep -c '^curl DELETE' "$STUB_LOG")" -eq 2 ]
}

@test "an ambiguous name lists the matches instead of acting" {
  fixture GET '/studios?workspaceId=200&max=100&offset=0' \
    "$(studio 999 demo running | jq -c '{studios: [.]}')"
  studios_in_research "$(studio 6afaa755 demo running)"

  run "$BIN" ssh demo
  [ "$status" -ne 0 ]
  [[ $output == *6afaa755* && $output == *999* ]]
  refute grep -q '^ssh' "$STUB_LOG"
}

@test "ssh opens a shell on the Studio" {
  studios_in_research "$(studio 6afaa755 demo running)"

  run "$BIN" ssh 6afaa755
  [ "$status" -eq 0 ]
  grep -qxF 'ssh -p 2222 edmund@a6afaa755@connect.cloud.seqera.io' "$STUB_LOG"
}

@test "start resumes a stopped Studio and brings its tunnel up" {
  studios_in_research "$(studio 6afaa755 demo stopped)"
  fixture PUT '/studios/6afaa755/start?workspaceId=100' '{}'
  fixture_seq GET '/studios/6afaa755?workspaceId=100' \
    "$(studio 6afaa755 demo stopped)" "$(studio 6afaa755 demo starting)" "$(studio 6afaa755 demo running)"

  run "$BIN" start demo
  [ "$status" -eq 0 ]
  grep -qxF 'curl PUT /studios/6afaa755/start?workspaceId=100 {}' "$STUB_LOG"
  grep -qxF 'io.seqera.rex-studio.a6afaa755' "$STUB_STATE/launchd-loaded"
}

@test "start reports a Studio whose Rex server never answers" {
  studios_in_research "$(studio 6afaa755 demo running)"
  touch "$STUB_STATE/rex-unreachable"

  run "$BIN" start demo
  [ "$status" -ne 0 ]
  [[ $output == *"a6afaa755.log"* ]]
}

@test "stop stops the Studio and its tunnel" {
  studios_in_research "$(studio 6afaa755 demo running)"
  run "$BIN" sync
  fixture PUT '/studios/6afaa755/stop?workspaceId=100' '{}'
  fixture_seq GET '/studios/6afaa755?workspaceId=100' "$(studio 6afaa755 demo running)" "$(studio 6afaa755 demo stopping)"

  run "$BIN" stop demo
  [ "$status" -eq 0 ]
  grep -qF 'curl PUT /studios/6afaa755/stop?workspaceId=100' "$STUB_LOG"
  [ ! -e "$PLIST" ]
}

@test "on Linux the tunnel is a systemd user service that restarts" {
  export STUB_OS=Linux
  studios_in_research "$(studio 6afaa755 demo running)"

  run "$BIN" sync
  [ "$status" -eq 0 ]
  unit=$XDG_CONFIG_HOME/systemd/user/rex-studio-a6afaa755.service
  grep -qxF 'Restart=always' "$unit"
  grep -qxF 'RestartSec=10' "$unit"
  grep -qF "\"-L\" \"127.0.0.1:$PORT:127.0.0.1:7297\" \"edmund@a6afaa755@connect.cloud.seqera.io\"" "$unit"
  grep -qxF 'rex-studio-a6afaa755.service' "$STUB_STATE/systemd-active"
  [ ! -e "$PLIST" ]

  studios_in_research
  run "$BIN" sync
  [ ! -e "$unit" ]
}

@test "doctor passes with a valid token, a visible workspace and an accepted key" {
  studios_in_research "$(studio 6afaa755 demo running)"

  run "$BIN" doctor
  [ "$status" -eq 0 ]
  refute grep -q FAIL <<<"$output"
  grep -qF 'ssh -o BatchMode=yes' "$STUB_LOG"
}

@test "doctor fails on a missing token, an unknown workspace, or a refused key" {
  run env -u TOWER_ACCESS_TOKEN "$BIN" doctor
  [ "$status" -ne 0 ]
  [[ $output == *"FAIL  TOWER_ACCESS_TOKEN"* ]]

  studios_in_research "$(studio 6afaa755 demo running)"
  REX_STUDIO_WORKSPACE=acme/nope SSH_STUB_EXIT=255 run "$BIN" doctor
  [ "$status" -ne 0 ]
  [[ $output == *"FAIL  workspace acme/nope"* ]]
  [[ $output == *"FAIL  ssh key refused"* ]]
}

@test "help prints usage" {
  run "$BIN" help
  [ "$status" -eq 0 ]
  [[ $output == *"rex-studio new"* && $output == *"TOWER_ACCESS_TOKEN"* ]]
}
