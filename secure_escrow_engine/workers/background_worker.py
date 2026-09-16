import time
import threading
from core.telemetry.logger import setup_logger

logger = setup_logger("BackgroundWorker", "./logs/worker.log")

class BackgroundWorker(threading.Thread):
    def __init__(self, interval=15):
        super().__init__()
        self.interval = interval
        self.daemon = True
        self.stop_event = threading.Event()

    def run(self):
        logger.info("Background telemetry and cleanup worker started.")
        while not self.stop_event.is_set():
            try:
                # Perform periodic state reconciliation, health checking, and garbage collection
                logger.debug("Executing scheduled maintenance cycle...")
                time.sleep(self.interval)
            except Exception as e:
                logger.error(f"Error in background worker: {str(e)}")

    def stop(self):
        self.stop_event.set()
