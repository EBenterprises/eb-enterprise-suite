#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/omega"

pkg update -y
pkg install -y nodejs

cd "$ROOT"

npm test

echo
echo "OMEGA® READY"
echo
echo "Launch UI:"
echo "cd $HOME/omega && npm start"
echo
echo "CLI:"
echo "cd $HOME/omega && node bin/omega.js status"
echo
echo "Then open:"
echo "http://127.0.0.1:8787"
