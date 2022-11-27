#!/usr/bin/env bash
set -euo pipefail

EMACS="eldev emacs"

COMMAND_SERVER_DIRECTORY=$($EMACS --batch --eval '(message (command-server-directory))')

cat << EOF > "$COMMAND_SERVER_DIRECTORY/request.json"
{
   "commandId": "eval",
   "args": [
      "(message \"hi from the command client!\")"
   ],
   "waitForFinish": true,
   "returnCommandOutput": true,
   "uuid": "205092cc-fa1a-4a51-989d-2a83307269b1"
}
EOF

$EMACS --eval '(server-start)'


# run this from a terminal
# emacsclient --eval "(call-interactively 'command-server-run-command)"
