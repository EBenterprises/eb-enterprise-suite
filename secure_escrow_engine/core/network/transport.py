import socket
import threading
import json
from core.telemetry.logger import setup_logger

logger = setup_logger("Transport", "./logs/transport.log")

class PeerTransport:
    def __init__(self, bind_ip, bind_port):
        self.bind_ip = bind_ip
        self.bind_port = bind_port
        self.running = False
        self.server_socket = None

    def start_listener(self, router_callback):
        self.running = True
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.bind_ip, self.bind_port))
        self.server_socket.listen(128)

        threading.Thread(target=self._accept_loop, args=(router_callback,), daemon=True).start()
        logger.info(f"Peer transport listener bound to {self.bind_ip}:{self.bind_port}")

    def _accept_loop(self, callback):
        while self.running:
            try:
                conn, addr = self.server_socket.accept()
                threading.Thread(target=self._handle_peer, args=(conn, addr, callback), daemon=True).start()
            except Exception as e:
                if self.running:
                    logger.error(f"Error accepting peer connection: {e}")

    def _handle_peer(self, conn, addr, callback):
        try:
            data = conn.recv(65536)
            if data:
                packet = json.loads(data.decode('utf-8'))
                response = callback(packet)
                conn.sendall(json.dumps(response).encode('utf-8'))
        except Exception as e:
            logger.error(f"Error handling peer request from {addr}: {e}")
        finally:
            conn.close()

    def stop(self):
        self.running = False
        if self.server_socket:
            self.server_socket.close()
