from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import numpy as np
import cv2
import os

app = Flask(__name__)
socketio = SocketIO(app)

# Create a directory to save frames if it doesn't exist
frames_dir = 'saved_frames'
if not os.path.exists(frames_dir):
    os.makedirs(frames_dir)

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('live_stream')
def handle_live_stream(data):
    try:
        # Convert the byte data to a numpy array
        nparr = np.frombuffer(data, np.uint8)
        
        # Decode the image
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if frame is None:
            print("Error: OpenCV could not decode the frame")
            return
        
        # Save the frame as a file in the designated folder
        frame_filename = os.path.join(frames_dir, f'frame_{cv2.getTickCount()}.jpg')
        cv2.imwrite(frame_filename, frame)
        print(f"Saved frame: {frame_filename}")

    except Exception as e:
        print(f"Error processing frame: {e}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
