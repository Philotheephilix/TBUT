import datetime
from flask import Flask
from flask_socketio import SocketIO, emit
import base64
import io
from PIL import Image
from inference_sdk import InferenceHTTPClient
from concurrent.futures import ThreadPoolExecutor
import logging
from pymongo import MongoClient

app = Flask(__name__)
socketio = SocketIO(app)

CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="vMHIxbNsc6wiOExiBDTq"
)

executor = ThreadPoolExecutor(max_workers=4)

logging.basicConfig(level=logging.INFO)
mongo_client = MongoClient("mongodb://localhost:27017/")
db = mongo_client['eye_tear_aravind'] 
predictions_collection = db['predictions']  

def perform_inference(image):
    result = CLIENT.infer(image, model_id="tbut_obj_classif/2")
    return result

@socketio.on('frame')
def handle_frame(data):
    image_data = data.get('image')
    client_id = data.get('client_id')
    doctor_id = data.get('doctor_id')
    patient_id = data.get('patient_id')

    if client_id is None:
        logging.error("Error: client_id not provided.")
        return

    if isinstance(image_data, str):
        image_data = base64.b64decode(image_data)

    if isinstance(image_data, bytes):
        image = Image.open(io.BytesIO(image_data))
        executor.submit(inference_worker, image, client_id, doctor_id, patient_id)
    else:
        logging.error("Error: Unable to process image data.")

def inference_worker(image, client_id, doctor_id, patient_id):
    result = perform_inference(image)
    logging.info(f"Inference result: {result}")

    document = {
        'doctor_id': doctor_id,
        'patient_id': patient_id,
        'result': result,
        'timestamp': datetime.datetime.now() 
    }

    predictions_collection.update_one(
        {
            'doctor_id': doctor_id,
            'patient_id': patient_id
        },
        {'$push': {'results': document}},
        upsert=True 
    )

    socketio.emit('inference_result', {
        'result': result,
        'doctor_id': doctor_id,
        'patient_id': patient_id
    }, room=client_id)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
