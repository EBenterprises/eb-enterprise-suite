import json

class ProtocolEngine:
    @staticmethod
    def encode_response(status_code: int, data: dict, error: str = None) -> bytes:
        packet = {
            "status": status_code,
            "data": data,
            "error": error
        }
        return json.dumps(packet).encode('utf-8')

    @staticmethod
    def decode_request(raw_data: bytes) -> dict:
        try:
            return json.loads(raw_data.decode('utf-8'))
        except Exception:
            return {}
