from collections import deque
from fastapi import FastAPI, Form, Request
from fastapi.responses import JSONResponse
import cv2
import logging
import threading
from queue import Queue
from ultralytics import YOLO
import uvicorn
import time
import httpx
import asyncio

app = FastAPI()
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class StreamProcessor:
    def __init__(self):
        self.active_streams = {}
        self.model = YOLO("./models/tbut_75_percent_Dec_27_2024.pt")
        self.queue = Queue(maxsize=10)
        self.start_times = {}
        self.client_addresses = {}  # Store client IP addresses

    def start_stream(self, stream_url, patient_id, client_address):
        def frame_producer():
            cap = cv2.VideoCapture(stream_url)
            self.start_times[patient_id] = time.time()
            while cap.isOpened() and patient_id in self.active_streams:
                ret, frame = cap.read()
                if not ret:
                    break
                try:
                    self.queue.put(frame, timeout=1)
                except Exception as e:
                    logger.warning(f"Queue is full, dropping frame: {e}")
            cap.release()
            logger.info(f"Frame capture ended for patient {patient_id}")

        def frame_consumer():
            async def send_elapsed_time(elapsed_time):
                try:
                    client_address = self.client_addresses.get(patient_id)
                    if client_address:
                        async with httpx.AsyncClient() as client:
                            response = await client.post(
                                f"http://{client_address}/detection-complete",
                                json={"elapsed_time": elapsed_time, "patient_id": patient_id}
                            )
                            logger.info(f"Sent elapsed time to client: {response.status_code}")
                except Exception as e:
                    logger.error(f"Error sending elapsed time to client: {e}")

            while patient_id in self.active_streams:
                try:
                    frame = self.queue.get(timeout=1)
                except Exception:
                    continue

                results = self.model(frame)
                for r in results:
                    for box in r.boxes:
                        confidence = float(box.conf)
                        if confidence > 0.50:
                            elapsed_time = float(time.time() - self.start_times[patient_id]) - 3
                            logger.info(f"Detection complete. Elapsed time: {elapsed_time}")
                            
                            # Create event loop and run the async function
                            loop = asyncio.new_event_loop()
                            asyncio.set_event_loop(loop)
                            loop.run_until_complete(send_elapsed_time(elapsed_time))
                            loop.close()
                            
                            self.stop_stream(patient_id)
                            return elapsed_time

        self.client_addresses[patient_id] = client_address
        self.active_streams[patient_id] = {
            "producer": threading.Thread(target=frame_producer, daemon=True),
            "consumer": threading.Thread(target=frame_consumer, daemon=True)
        }
        self.active_streams[patient_id]["producer"].start()
        self.active_streams[patient_id]["consumer"].start()

    def stop_stream(self, patient_id):
        if patient_id in self.active_streams:
            del self.active_streams[patient_id]
            if patient_id in self.client_addresses:
                del self.client_addresses[patient_id]

processor = StreamProcessor()

@app.post("/api/start")
async def start_detection(
    request: Request,
    doctorId: str = Form(...),
    patientId: str = Form(...),
    streamUrl: str = Form(...)
):
    try:
        client_address = request.client.host
        elapsed_time = None
        
        def consumer_thread():
            nonlocal elapsed_time
            elapsed_time = processor.start_stream(streamUrl, patientId, client_address)
        
        thread = threading.Thread(target=consumer_thread)
        thread.start()
        thread.join()

        return JSONResponse(content={"elapsed_time": elapsed_time}, status_code=200)
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.post("/api/stop")
async def stop_detection(patientId: str = Form(...)):
    try:
        processor.stop_stream(patientId)
        return JSONResponse(content={"message": f"Stream stopped for patient {patientId}"}, status_code=200)
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)