from flask import Flask, request
from flask_socketio import SocketIO
import base64
import os
from datetime import datetime

app = Flask(__name__)
socketio = SocketIO(app)

SAVE_FOLDER = 'frames'
os.makedirs(SAVE_FOLDER, exist_ok=True)

@socketio.on('frame')
def handle_frame(data):
    image_data = data.get('image')
    if isinstance(image_data, str):
        image_data = base64.b64decode(image_data)
    if isinstance(image_data, bytes):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
        filename = f"{SAVE_FOLDER}/{timestamp}.jpg"
        # Write the binary data to a file
        with open(filename, 'wb') as f:
            f.write(image_data)

        print(f"Received frame and saved as {filename}")
    else:
        print("Error: Unable to process image data.")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
