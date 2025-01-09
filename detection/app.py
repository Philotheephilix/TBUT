from collections import deque
from fastapi import FastAPI, Form
from fastapi.responses import JSONResponse
import cv2
import logging
import threading
from queue import Queue
from ultralytics import YOLO
import uvicorn
import time

app = FastAPI()
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class StreamProcessor:
    def __init__(self):
        self.active_streams = {}
        self.model = YOLO("./models/tbut_75_percent_Dec_27_2024.pt")
        # self.model = YOLO("./models/tbut_75_percent_Dec_27_2024.pt").to("cuda") 
        self.queue = Queue(maxsize=10)  # Limit the queue size to avoid memory issues
    
    def start_stream(self, stream_url, patient_id):
        def frame_producer():
            cap = cv2.VideoCapture(stream_url)
            while cap.isOpened() and patient_id in self.active_streams:
                ret, frame = cap.read()
                if not ret:
                    break
                try:
                    self.queue.put(frame, timeout=1)  # Add frame to the queue
                except Exception as e:
                    logger.warning(f"Queue is full, dropping frame: {e}")
            cap.release()
            logger.info(f"Frame capture ended for patient {patient_id}")

        def frame_consumer():
            fps_counter = FPSCounter()
            while patient_id in self.active_streams:
                try:
                    frame = self.queue.get(timeout=1)  # Get frame from the queue
                except Exception:
                    continue  # Skip if queue is empty
                fps_counter.update()
                results = self.model(frame)  # Process frame using YOLO
                for r in results:
                    for box in r.boxes:
                        logger.info(f"Detection: {self.model.names[int(box.cls)]} ({float(box.conf):.2f})")
                
                # Log FPS every second
                if time.time() - fps_counter.last_log >= 1:
                    logger.info(f"FPS: {fps_counter.get_fps():.2f}")
                    fps_counter.last_log = time.time()
        
        # Start producer and consumer threads
        self.active_streams[patient_id] = {
            "producer": threading.Thread(target=frame_producer, daemon=True),
            "consumer": threading.Thread(target=frame_consumer, daemon=True)
        }
        self.active_streams[patient_id]["producer"].start()
        self.active_streams[patient_id]["consumer"].start()
    
    def stop_stream(self, patient_id):
        if patient_id in self.active_streams:
            del self.active_streams[patient_id]

class FPSCounter:
    def __init__(self):
        self.frame_times = deque(maxlen=30)
        self.last_log = time.time()
    
    def update(self):
        self.frame_times.append(time.time())
    
    def get_fps(self):
        if len(self.frame_times) < 2:
            return 0
        return len(self.frame_times) / (self.frame_times[-1] - self.frame_times[0])

processor = StreamProcessor()

@app.post("/api/start")
async def start_detection(
    doctorId: str = Form(...),
    patientId: str = Form(...),
    streamUrl: str = Form(...)
):
    try:
        processor.start_stream(streamUrl, patientId)
        return JSONResponse(content={"message": "Processing started"}, status_code=200)
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
