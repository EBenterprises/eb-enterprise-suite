import socket

print("Scanning ports 3000 to 3110 for active listeners...")
for port in range(3000, 3110):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.05)
        result = s.connect_ex(('127.0.0.1', port))
        if result == 0:
            print(f"--> Found active listener on port {port}")
