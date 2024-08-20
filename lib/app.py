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
    image_data = base64.b64decode(data['image'])
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    filename = f"{SAVE_FOLDER}/{timestamp}.jpg"
    
    with open(filename, 'wb') as f:
        f.write(image_data)

    print(f"Received frame and saved as {filename}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
