from flask import Flask, request
from flask_socketio import SocketIO
import base64

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

@app.route('/')
def index():
    return "Server is running"

@socketio.on('video_frame')
def handle_video_frame(data):
    try:
        width = data['width']
        height = data['height']
        planes = data['planes']
        format = data['format']

        # Decode each plane's bytes from Base64
        for plane in planes:
            bytes_data = base64.b64decode(plane['bytes'])
            bytes_per_row = plane['bytesPerRow']
            bytes_per_pixel = plane['bytesPerPixel']

            # Process the bytes_data as needed
            # ...

        print(f"Received frame: {width}x{height}, format: {format}")
    except KeyError as e:
        print(f"Missing key: {e}")
    except Exception as e:
        print(f"Error processing frame: {e}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=8765)
