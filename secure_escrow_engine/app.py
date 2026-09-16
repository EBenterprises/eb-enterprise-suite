import http.server
import socketserver
import json
import os
from database import init_db, create_transaction

PORT = 8080

class EscrowHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Serve index.html from templates if root is requested
        if path == '/' or path == '':
            return os.path.join(os.getcwd(), 'templates', 'index.html')
        return super().translate_path(path)

    def do_POST(self):
        if self.path == '/api/transaction':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            create_transaction(data.get('id'), data.get('buyer'), data.get('vendor'), data.get('amount'))
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"status": "success", "state": "FUNDS_LOCKED"}
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    init_db()
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    with socketserver.TCPServer(("", PORT), EscrowHandler) as httpd:
        print(f"Escrow Engine running on port {PORT}")
        httpd.serve_forever()
