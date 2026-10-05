#!/bin/bash
echo "=== Current Repository Status ==="
git status
echo "=== Checking Instances ==="
for d in v1 v2 v3 v4 v5; do
  if [ -d "$d" ]; then
    echo "Directory $d exists."
  else
    echo "Directory $d missing."
  fi
done
