const express = require('express');
const app = express();

app.use(express.json());

app.post('/stream/start', async (req, res) => {
  try {
    const { doctorId, patientId, streamUrl, timestamp = new Date().toISOString() } = req.body;

    if (!doctorId || !patientId || !streamUrl) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields. Please provide doctorId, patientId, and streamUrl'
      });
    }
    const streamInfo = {
      doctorId,
      patientId,
      streamUrl,
      timestamp,
    };
    console.log('New Stream Started:', JSON.stringify(streamInfo, null, 2));

    return res.status(200).json({
      success: true,
      data: streamInfo
    });
  } catch (error) {
    console.error('Error logging stream:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while logging stream information'
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});