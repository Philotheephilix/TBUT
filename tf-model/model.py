import tensorflow as tf
from tensorflow.keras import layers, models
import numpy as np
import matplotlib.pyplot as plt
import os

BATCH_SIZE = 4
IMAGE_SIZE = (640, 640)
NUM_CHANNELS = 3

def load_and_preprocess_image(image_path):
    """
    Load and preprocess single image
    """
    # Read image file
    image_raw = tf.io.read_file(image_path)
    
    # Decode image 
    image = tf.image.decode_image(image_raw, channels=NUM_CHANNELS)
    
    # Ensure image has a defined shape
    image.set_shape([None, None, NUM_CHANNELS])
    
    # Resize image
    image = tf.image.resize(image, IMAGE_SIZE)
    
    # Normalize
    image = image / 255.0
    
    return image

def create_dataset(directory):
    """
    Create dataset from image directory
    """
    image_paths = [
        os.path.join(directory, fname) 
        for fname in os.listdir(directory) 
        if fname.lower().endswith(('.png', '.jpg', '.jpeg'))
    ]
    
    dataset = tf.data.Dataset.from_tensor_slices(image_paths)
    
    # Map preprocessing
    dataset = dataset.map(
        lambda x: (load_and_preprocess_image(x), tf.constant(1.0, dtype=tf.float32)),
        num_parallel_calls=tf.data.AUTOTUNE
    )
    
    # Batch and prefetch
    dataset = dataset.batch(BATCH_SIZE)
    dataset = dataset.prefetch(tf.data.AUTOTUNE)
    
    return dataset

def create_memory_efficient_model(input_shape):
    """
    Lightweight model for large images
    """
    model = models.Sequential([
        layers.InputLayer(input_shape=input_shape),
        layers.Conv2D(16, 3, activation='relu', strides=2),
        layers.MaxPooling2D(),
        layers.Conv2D(32, 3, activation='relu', strides=2),
        layers.MaxPooling2D(),
        layers.Conv2D(64, 3, activation='relu'),
        layers.GlobalAveragePooling2D(),
        layers.Dense(1, activation='sigmoid')
    ])
    
    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    return model

def train_model(train_dir, test_dir):
    """
    Train with robust dataset handling
    """
   
    train_dataset = create_dataset(train_dir)
    test_dataset = create_dataset(test_dir)
    
    model = create_memory_efficient_model((*IMAGE_SIZE, NUM_CHANNELS))
    model.summary()
    
    history = model.fit(
        train_dataset,
        validation_data=test_dataset,
        epochs=10
    )
    
    test_results = model.evaluate(test_dataset)
    print(f"\nTest Accuracy: {test_results[1] * 100:.2f}%")
    
    model.save('efficient_large_image_model.h5')

TRAIN_DIR = os.path.join(os.getcwd(), 'train')
TEST_DIR = os.path.join(os.getcwd(), 'test')

train_model(TRAIN_DIR, TEST_DIR)