from flask import Flask
from flask_socketio import SocketIO, emit
import base64
import io
from PIL import Image
from inference_sdk import InferenceHTTPClient
from concurrent.futures import ThreadPoolExecutor

app = Flask(__name__)
socketio = SocketIO(app)

# Initialize the inference client
CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="vMHIxbNsc6wiOExiBDTq"
)

# Set up a thread pool for handling inference requests
executor = ThreadPoolExecutor(max_workers=4)

def perform_inference(image):
    # Perform inference on the image
    result = CLIENT.infer(image, model_id="tbut_obj_classif/2")
    return result

@socketio.on('frame')
def handle_frame(data):
    image_data = data.get('image')
    
    # Ensure client_id is included in the data
    client_id = data.get('client_id')
    if client_id is None:
        print("Error: client_id not provided.") 
        return

    if isinstance(image_data, str):
        image_data = base64.b64decode(image_data)

    if isinstance(image_data, bytes):
        # Convert bytes to PIL image
        image = Image.open(io.BytesIO(image_data))
        
        # Submit the inference task to the thread pool
        executor.submit(inference_worker, image, client_id)

    else:
        print("Error: Unable to process image data.")

def inference_worker(image, client_id):
    # This function runs in a separate thread
    result = perform_inference(image)
    print(f"Inference result: {result}")

    # Emit the result back to the client
    socketio.emit('inference_result', {'result': result}, room=client_id)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
