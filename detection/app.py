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
import socket

app = FastAPI()
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
Sensitivity = 0.5
def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception as e:
        logger.error(f"Error getting local IP: {e}")
        return "127.0.0.1"
    
class StreamProcessor:
    def __init__(self):
        self.active_streams = {}
        self.model = YOLO("./models/tbut_75_percent_Dec_27_2024.pt")
        self.queue = Queue(maxsize=10)
        self.start_times = {}
        self.client_addresses = {}  # Store client IP addresses
        self.client = httpx.AsyncClient()
    async def notify_client(self, client_address, patient_id, elapsed_time):
        try:
            response = await self.client.post(
                f"http://{client_address}:8080/detection-complete",
                json={
                    "patient_id": patient_id,
                    "elapsed_time": elapsed_time
                },
                timeout=10.0
            )
            logger.info(f"Notification sent to client. Status: {response.status_code}")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Error notifying client: {e}")
            return False
    def start_stream(self, patient_id, client_address,doctor_id):
        def frame_producer():
            streamUrl="rtmp://"+str(get_local_ip())+':1935/live/'+str(doctor_id)+str(patient_id)
            print(streamUrl)
            cap = cv2.VideoCapture(streamUrl)
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

            while patient_id in self.active_streams:
                try:
                    frame = self.queue.get(timeout=1)
                except Exception:
                    continue
                results = self.model(frame)
                for r in results:
                    for box in r.boxes:
                        confidence = float(box.conf)
                        if confidence > float(Sensitivity):
                            elapsed_time = float(time.time() - self.start_times[patient_id]) - 3
                            logger.info(f"Detection complete. Elapsed time: {elapsed_time}")
                            
                            client_address = self.client_addresses.get(patient_id)
                            if client_address:
                                # Create new event loop for async operation
                                loop = asyncio.new_event_loop()
                                asyncio.set_event_loop(loop)
                                try:
                                    loop.run_until_complete(
                                        self.notify_client(client_address, patient_id, elapsed_time)
                                    )
                                finally:
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
    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()
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
    sensitivity: str = Form(...)
):
    global Sensitivity
    Sensitivity = float(sensitivity)
    print(sensitivity,get_local_ip())
    try:
        client_address = request.client.host
        elapsed_time = None
        
        def consumer_thread():
            nonlocal elapsed_time
            elapsed_time = processor.start_stream(patientId, client_address,doctorId)
        
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