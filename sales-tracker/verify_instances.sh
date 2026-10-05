#!/bin/bash
for d in v1 v2 v3 v4 v5; do
  echo "--- Instance $d ---"
  if [ -f "$d/server.js" ]; then
    echo "server.js exists ($(wc -l < "$d/server.js") lines)"
  else
    echo "server.js missing!"
  fi
  if [ -f "$d/transactions.json" ]; then
    echo "transactions.json exists"
  elif [ -f "transactions.json" ]; then
    echo "Using root transactions.json"
  fi
done
