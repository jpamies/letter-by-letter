const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));

// Route to composite images
app.post('/composite', async (req, res) => {
  try {
    const { images } = req.body;
    
    if (!images || !Array.isArray(images) || images.length === 0) {
      return res.status(400).json({ error: 'Images array is required' });
    }
    
    // In a real implementation, we would use a library like Sharp to composite the images
    // For now, we'll just return a mock composite image
    
    // Simulate processing time
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Create a simple SVG that places all images side by side
    const svgWidth = images.length * 50;
    const svgContent = `
      <svg xmlns="http://www.w3.org/2000/svg" width="${svgWidth}" height="50">
        ${images.map((image, i) => `
          <image href="${image}" x="${i * 50}" y="0" width="50" height="50" />
        `).join('')}
      </svg>
    `;
    
    const base64Image = Buffer.from(svgContent).toString('base64');
    
    res.json({
      compositeImage: `data:image/svg+xml;base64,${base64Image}`
    });
  } catch (error) {
    console.error('Error compositing images:', error);
    res.status(500).json({ error: 'Failed to composite images' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Image compositor service running on port ${PORT}`);
});
