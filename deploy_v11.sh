#!/usr/bin/env bash
set -e

test -f index.html || { echo "Error: index.html missing"; exit 1; }
test -f style.css || { echo "Error: style.css missing"; exit 1; }

python3 -c "
import socket
import http.server
import socketserver

start_port = 8080
max_port = 8090

for port in range(start_port, max_port + 1):
    try:
        class ReusableTCPServer(socketserver.TCPServer):
            allow_reuse_address = True

        handler = http.server.SimpleHTTPRequestHandler
        with ReusableTCPServer(('', port), handler) as httpd:
            print(f'=> V11 Live on http://localhost:{port}')
            httpd.serve_forever()
            break
    except OSError:
        continue
"
