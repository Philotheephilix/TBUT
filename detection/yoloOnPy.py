from ultralytics import YOLO
import os
import cv2

model_path = "./models/tbut_75_percent_Dec_27_2024.pt"  # Path to your YOLO model file
test_images_path = "./dataset/test/images"  # Folder containing test images

# Load the YOLO model
model = YOLO(model_path)

# Output directory for annotated images
output_dir = "output"
os.makedirs(output_dir, exist_ok=True)  # Create the output directory if it doesn't exist
results = model.val(data="./imgs/data.yaml") 
# Loop through the test images and perform inference
for image_name in os.listdir(test_images_path):
    image_path = os.path.join(test_images_path, image_name)
    
    if image_name.endswith(('.png', '.jpg', '.jpeg')):  # Ensure the file is an image
        print(f"Processing: {image_name}")
        
        # Perform inference
        results = model(image_path)

        # Loop through results and save annotated images
        for i, result in enumerate(results):
            # Generate annotated image
            annotated_image = result.plot()  # Creates an annotated numpy array
            
            # Define the save path for the annotated image
            save_path = os.path.join(output_dir, f"{os.path.splitext(image_name)[0]}annotated{i}.jpg")
            
            # Save the annotated image using OpenCV
            cv2.imwrite(save_path, annotated_image)

print(f"Inference complete. Results saved in the '{output_dir}' folder.")
print(results)