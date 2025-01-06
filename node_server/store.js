const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');

// Create output directory for frames if it doesn't exist
const framesDir = path.join(__dirname, 'frames');
if (!fs.existsSync(framesDir)) {
    fs.mkdirSync(framesDir);
}

// Configuration
const config = {
    sourceRtmpUrl: 'rtmp://172.31.98.86:1935/live/your_stream', // Replace with source server IP
    frameRate: 30, // Frames per second to extract
    outputQuality: 80 // JPEG quality (1-100)
};

// Function to start frame extraction
function startFrameExtraction() {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const sessionDir = path.join(framesDir, timestamp);
    
    // Create directory for this session
    if (!fs.existsSync(sessionDir)) {
        fs.mkdirSync(sessionDir);
    }

    console.log(`Starting frame extraction from ${config.sourceRtmpUrl}`);
    console.log(`Saving frames to ${sessionDir}`);

    ffmpeg(config.sourceRtmpUrl)
        .outputOptions([
            `-vf fps=${config.frameRate}`,
            '-frame_pts 1',
            `-q:v ${Math.floor((100 - config.outputQuality) / 4)}` // Convert quality to FFmpeg's scale
        ])
        .output(path.join(sessionDir, 'frame-%d.jpg'))
        .on('start', () => {
            console.log('Frame extraction started');
            console.log(`Extracting ${config.frameRate} frame(s) per second`);
        })
        .on('error', (err, stdout, stderr) => {
            console.error('Error during frame extraction:', err.message);
            console.log('FFmpeg output:', stdout);
            console.error('FFmpeg errors:', stderr);
            
            // Attempt to reconnect after a delay
            console.log('Attempting to reconnect in 5 seconds...');
            setTimeout(startFrameExtraction, 5000);
        })
        .on('end', () => {
            console.log('Frame extraction ended');
            // Attempt to reconnect as the stream might have ended unexpectedly
            console.log('Stream ended, attempting to reconnect...');
            startFrameExtraction();
        })
        // Progress logging (optional)
        .on('progress', (progress) => {
            if (progress.frames) {
                console.log(`Extracted ${progress.frames} frames`);
            }
        })
        .run();
}

// Start the frame extraction process
console.log('Frame extraction server starting...');
console.log('Configuration:', config);
startFrameExtraction();

// Handle process termination
process.on('SIGINT', () => {
    console.log('Gracefully shutting down...');
    process.exit(0);
});