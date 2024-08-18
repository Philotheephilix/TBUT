from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import base64
import cv2
import numpy as np

app = Flask(__name__)
socketio = SocketIO(app)

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('live_stream')
def handle_live_stream(data):
    try:
        print(f"Received data length: {len(data)}")
        decoded_data = base64.b64decode(data)
        print(f"Decoded data length: {len(decoded_data)}")
        
        # Convert the byte data to a numpy array
        frame = np.frombuffer(decoded_data, dtype=np.uint8)
        if frame.size == 0:
            print("Error: Received an empty frame")
            return
        
        # Decode the image
        frame = cv2.imdecode(frame, cv2.IMREAD_COLOR)
        if frame is None:
            print("Error: OpenCV could not decode the frame")
            return
        
        # Display the image (for local testing, remove this in production)
        cv2.imshow('Live Stream', frame)
        cv2.waitKey(1)

        # Encode the frame as base64 to send back
        _, buffer = cv2.imencode('.jpg', frame)
        encoded_frame = base64.b64encode(buffer).decode('utf-8')

        # Emit the processed frame
        socketio.emit('live_stream', encoded_frame)
        
    except Exception as e:
        print(f"Error processing frame: {e}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
from flask import Flask, render_template
from flask_socketio import SocketIO, emit
import base64
import cv2
import numpy as np

app = Flask(__name__)
socketio = SocketIO(app)

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('live_stream')
def handle_live_stream(data):
    try:
        print(f"Received data length: {len(data)}")
        decoded_data = base64.b64decode(data)
        print(f"Decoded data length: {len(decoded_data)}")
        
        # Convert the byte data to a numpy array
        frame = np.frombuffer(decoded_data, dtype=np.uint8)
        if frame.size == 0:
            print("Error: Received an empty frame")
            return
        
        # Decode the image
        frame = cv2.imdecode(frame, cv2.IMREAD_COLOR)
        if frame is None:
            print("Error: OpenCV could not decode the frame")
            return
        
        # Display the image (for local testing, remove this in production)
        cv2.imshow('Live Stream', frame)
        cv2.waitKey(1)

        # Encode the frame as base64 to send back
        _, buffer = cv2.imencode('.jpg', frame)
        encoded_frame = base64.b64encode(buffer).decode('utf-8')

        # Emit the processed frame
        socketio.emit('live_stream', encoded_frame)
        
    except Exception as e:
        print(f"Error processing frame: {e}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
