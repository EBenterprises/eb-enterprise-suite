import http.server
import socketserver
import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from api.router import Router
from database.schema import init_database

PORT = 8080

class CoreEngineHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/api/'):
            status, payload = Router.handle_request(self.path, 'GET', self.headers, b'')
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode('utf-8'))
        else:
            if self.path == '/' or self.path == '':
                self.path = '/templates/index.html'
            file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), self.path.lstrip('/'))
            if os.path.exists(file_path):
                self.send_response(200)
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()

    def do_POST(self):
        if self.path.startswith('/api/'):
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            status, payload = Router.handle_request(self.path, 'POST', self.headers, post_data)
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    init_database()
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    with socketserver.TCPServer(("", PORT), CoreEngineHandler) as httpd:
        print(f"[+] Dark Market Core Engine Active on Port {PORT}")
        httpd.serve_forever()
