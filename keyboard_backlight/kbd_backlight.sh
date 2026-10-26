#!/usr/bin/bash
set -euo pipefail
exec /usr/bin/pkexec /usr/local/libexec/acer-kbd-control "$@"
