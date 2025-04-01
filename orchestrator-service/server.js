const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Mock service for the first iteration
const mockLetterService = async (letter) => {
  // Simulate processing time between 50-200ms
  const processingTime = Math.floor(Math.random() * 150) + 50;
  
  // Simulate a network request
  await new Promise(resolve => setTimeout(resolve, processingTime));
  
  // Return a mock base64 image (a colored rectangle with the letter)
  // In a real implementation, this would be an actual image
  return {
    imageData: `data:image/svg+xml;base64,${Buffer.from(`
      <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">
        <rect width="50" height="50" fill="#${Math.floor(Math.random()*16777215).toString(16)}" />
        <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="30" fill="white">${letter}</text>
      </svg>
    `).toString('base64')}`,
    processingTime
  };
};

// Route to generate image from text
app.post('/generate', async (req, res) => {
  try {
    const { text } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }
    
    const startTime = Date.now();
    const serviceBreakdown = [];
    const letterPromises = [];
    
    // Process each character in the text
    for (const char of text) {
      letterPromises.push(
        mockLetterService(char).then(result => {
          serviceBreakdown.push({
            name: `Service-${char.toUpperCase()}`,
            time: result.processingTime
          });
          return result.imageData;
        })
      );
    }
    
    // Wait for all letter services to complete
    const letterImages = await Promise.all(letterPromises);
    
    // Call the image compositor service (mocked for now)
    const compositeStartTime = Date.now();
    
    // Simulate image compositor service delay
    await new Promise(resolve => setTimeout(resolve, 100));
    
    const compositeTime = Date.now() - compositeStartTime;
    serviceBreakdown.push({
      name: 'Image-Compositor',
      time: compositeTime
    });
    
    // In a real implementation, we would send the letter images to the compositor service
    // For now, we'll just return a mock composite image URL
    const totalTime = Date.now() - startTime;
    
    res.json({
      imageUrl: `data:image/svg+xml;base64,${Buffer.from(`
        <svg xmlns="http://www.w3.org/2000/svg" width="${text.length * 50}" height="50">
          ${letterImages.map((_, i) => `
            <image href="${letterImages[i]}" x="${i * 50}" y="0" width="50" height="50" />
          `).join('')}
        </svg>
      `).toString('base64')}`,
      metrics: {
        totalTime,
        servicesUsed: serviceBreakdown.length,
        charactersProcessed: text.length,
        serviceBreakdown
      }
    });
  } catch (error) {
    console.error('Error generating image:', error);
    res.status(500).json({ error: 'Failed to generate image' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Orchestrator service running on port ${PORT}`);
});
