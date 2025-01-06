const NodeMediaServer = require('node-media-server');
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');

// Store ffmpeg processes and their associated data
const streamProcesses = new Map();
const config = {
  logType: 2,

  rtmp: {
    port: 1935,
    chunk_size: 128000,
    gop_cache: true,
    ping: 15,
    ping_timeout: 30,
    gop_cache_size: 60,
    wait_for_keyframe: true,
    wait_for_video: true
  },

  trans: {
    ffmpeg: '/usr/bin/ffmpeg',
    tasks: [
      {
        app: 'live',
        hls: true,
        hlsFlags: '[hls_time=1:hls_list_size=4:hls_flags=delete_segments+discont_start+independent_segments:hls_segment_type=fmp4]',
        
        dash: true,
        dashFlags: '[f=dash:min_seg_duration=2000:window_size=4:extra_window_size=3:use_template=1:use_timeline=1]',
        
        hlsOptions: {
          'hls_init_time': 0,
          'hls_time': 1,
          'hls_segment_filename': 'stream-%d.ts'
        },
        
        videoCodec: 'libx264',
        videoCodecOptions: [
          '-preset veryfast',
          '-profile:v high',
          '-level:v 4.1',
          '-tune zerolatency',
          '-x264opts keyint=60:min-keyint=60',
          '-crf 23',
          // Added framerate settings
          '-r 30',            // 60fps output
          '-vsync 1',         // Maintain consistent frame timing
          // Added resolution settings
          '-vf scale=1920:1080:flags=lanczos', // 1080p with high-quality scaling
          // Added additional quality settings for frame handling
          '-force_key_frames expr:gte(t,n_forced*2)', // Force keyframe every 2 seconds
          '-rc-lookahead 60',  // Lookahead buffer for better quality
          '-maxrate 6000k',    // Maximum bitrate
          '-bufsize 12000k',   // Buffer size (2x maxrate)
          '-g 120'            // GOP size (2 seconds at 60fps)
        ],
        
        audioCodec: 'aac',
        audioCodecOptions: [
          '-b:a 128k',
          '-ar 48000'
        ],

        // Added input settings to handle various source framerates
        inputOptions: [
          '-thread_queue_size 512',     // Increased thread queue for high fps
          '-fps_mode vfr',              // Variable framerate support
          '-re',                        // Read input at native framerate
          '-copytb 1'                   // Maintain timestamp consistency
        ]
      }
    ]
  }
};

const nms = new NodeMediaServer(config);
nms.run();
