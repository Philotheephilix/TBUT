from flask import Flask, request
from flask_socketio import SocketIO
import base64
import io
from datetime import datetime
from PIL import Image
from inference_sdk import InferenceHTTPClient

app = Flask(__name__)
socketio = SocketIO(app)

# Initialize the inference client
CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="vMHIxbNsc6wiOExiBDTq"
)

@socketio.on('frame')
def handle_frame(data):
    image_data = data.get('image')
    
    if isinstance(image_data, str):
        image_data = base64.b64decode(image_data)

    if isinstance(image_data, bytes):
        # Convert bytes to PIL image
        image = Image.open(io.BytesIO(image_data))
        
        # Perform inference on the image
        result = CLIENT.infer(image, model_id="tbut_obj_classif/2")

        # Process the result as needed (this is where you can handle the output)
        print(f"Inference result: {result}")

    else:
        print("Error: Unable to process image data.")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
