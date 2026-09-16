import http.server
import socketserver
import os

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

START_PORT = 8080
MAX_PORT = 8095
Handler = http.server.SimpleHTTPRequestHandler

os.chdir(os.path.dirname(os.path.abspath(__file__)))

server_started = False
for port in range(START_PORT, MAX_PORT + 1):
    try:
        with ReusableTCPServer(("", port), Handler) as httpd:
            print(f"\n======================================================")
            print(f"=> Executive Auth Architecture Live: http://localhost:{port}")
            print(f"======================================================\n")
            server_started = True
            httpd.serve_forever()
            break
    except OSError:
        continue

if not server_started:
    print(f"Error: All ports in range {START_PORT}-{MAX_PORT} are busy.")
