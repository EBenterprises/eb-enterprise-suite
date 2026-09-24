#!/bin/bash
echo "[DEPLOY] Initializing live synchronization for EB Enterprises®..."
npm run init:structure
npm run compile:manifest
echo "[SUCCESS] Official EB Enterprises® platform built and live daemon ready."
