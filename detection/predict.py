from ultralytics import YOLO
import cv2

def predict_single_frame(frame, model_path, save_output=False, output_path=None):
    model = YOLO(model_path)
    
    results = model(frame)
    for r in results:
        boxes = r.boxes
        for box in boxes:
            confidence = float(box.conf)
            class_id = int(box.cls)
            class_name = model.names[class_id]
            
            print(f"Detected {class_name} with confidence: {confidence:.2f}")
    
    if save_output:
        annotated_frame = results[0].plot()
        if output_path:
            cv2.imwrite(output_path, annotated_frame)
        return results, annotated_frame
    
    return results

# Example usage:

# For a single image file:
image = cv2.imread("./dataset/test/images/254_jpg.rf.a88c917aeaf6bd432e4bd20246779910.jpg")
results = predict_single_frame(
    frame=image,
    model_path="./models/tbut_75_percent_Dec_27_2024.pt",
    save_output=False,
    output_path=None)
"""
# For video frame:
cap = cv2.VideoCapture(0)  # or video file path
ret, frame = cap.read()
if ret:
    results = predict_single_frame(
        frame=frame,
        model_path="./models/tbut_75_percent_Dec_27_2024.pt",
        save_output=True,
        output_path="annotated_frame.jpg"
    )
cap.release()
"""