const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const pino = require('pino');
const pinoHttp = require('pino-http');

const app = express();
const PORT = process.env.PORT || 3001;

// Configure logger
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => {
      return { level: label };
    }
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(pinoHttp({ logger }));

// Service discovery configuration
// In a production environment, this would use service discovery (e.g., Kubernetes DNS)
// For local development, we use environment variables or defaults
const getServiceUrl = (serviceType, char) => {
  if (serviceType === 'letter') {
    // For letters A-Z
    const letterServiceBaseUrl = process.env.LETTER_SERVICE_BASE_URL || 'http://letter-service:3000';
    return `${letterServiceBaseUrl}`;
  } else if (serviceType === 'number') {
    // For numbers 0-9
    const numberServiceBaseUrl = process.env.NUMBER_SERVICE_BASE_URL || 'http://number-service:3000';
    return `${numberServiceBaseUrl}`;
  } else if (serviceType === 'special') {
    // For special characters
    const specialCharServiceUrl = process.env.SPECIAL_CHAR_SERVICE_URL || 'http://special-char-service:3000';
    return specialCharServiceUrl;
  } else if (serviceType === 'compositor') {
    // For image compositor
    const compositorServiceUrl = process.env.IMAGE_COMPOSITOR_SERVICE_URL || 'http://image-compositor-service:3000';
    return compositorServiceUrl;
  }
  
  throw new Error(`Unknown service type: ${serviceType}`);
};

// Determine the service type for a character
const getServiceTypeForChar = (char) => {
  if (/^[A-Za-z]$/.test(char)) {
    return 'letter';
  } else if (/^[0-9]$/.test(char)) {
    return 'number';
  } else {
    return 'special';
  }
};

// Call the appropriate service for a character
const callCharacterService = async (char, style = 'default') => {
  const serviceType = getServiceTypeForChar(char);
  const serviceUrl = getServiceUrl(serviceType);
  const startTime = Date.now();
  
  try {
    logger.info({ char, serviceType, serviceUrl }, 'Calling character service');
    
    let requestBody = {};
    if (serviceType === 'letter') {
      requestBody = { letter: char, style };
    } else if (serviceType === 'number') {
      requestBody = { number: char, style };
    } else {
      requestBody = { character: char, style };
    }
    
    const response = await axios.post(`${serviceUrl}/generate`, requestBody, {
      responseType: 'arraybuffer',
      timeout: 5000 // 5 second timeout
    });
    
    const processingTime = Date.now() - startTime;
    
    // Convert the image buffer to base64
    const imageBase64 = Buffer.from(response.data).toString('base64');
    const imageData = `data:image/png;base64,${imageBase64}`;
    
    return {
      imageData,
      processingTime,
      serviceType,
      success: true
    };
  } catch (error) {
    logger.error({ char, serviceType, error: error.message }, 'Error calling character service');
    
    // Generate a fallback image for the character
    return {
      imageData: generateFallbackImage(char),
      processingTime: Date.now() - startTime,
      serviceType,
      success: false,
      error: error.message
    };
  }
};

// Generate a fallback image for when a service call fails
const generateFallbackImage = (char) => {
  // Simple SVG fallback image
  return `data:image/svg+xml;base64,${Buffer.from(`
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
      <rect width="200" height="200" fill="#ffcccc" />
      <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="100" fill="#cc0000">${char}</text>
      <text x="50%" y="80%" dominant-baseline="middle" text-anchor="middle" font-size="20" fill="#cc0000">Error</text>
    </svg>
  `).toString('base64')}`;
};

// Call the image compositor service
const callImageCompositorService = async (images) => {
  try {
    const compositorUrl = getServiceUrl('compositor');
    const startTime = Date.now();
    
    logger.info({ compositorUrl, imageCount: images.length }, 'Calling image compositor service');
    
    // For now, we'll just combine the images client-side
    // In a real implementation, we would call the image compositor service
    
    // Simulate image compositor service delay
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Create a simple SVG that places the images side by side
    const compositeImageData = `data:image/svg+xml;base64,${Buffer.from(`
      <svg xmlns="http://www.w3.org/2000/svg" width="${images.length * 200}" height="200">
        ${images.map((img, i) => `
          <image href="${img}" x="${i * 200}" y="0" width="200" height="200" />
        `).join('')}
      </svg>
    `).toString('base64')}`;
    
    return {
      imageData: compositeImageData,
      processingTime: Date.now() - startTime,
      success: true
    };
  } catch (error) {
    logger.error({ error: error.message }, 'Error calling image compositor service');
    return {
      imageData: null,
      processingTime: 0,
      success: false,
      error: error.message
    };
  }
};

// Route to generate image from text
app.post('/generate', async (req, res) => {
  try {
    const { text, style = 'default' } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }
    
    const startTime = Date.now();
    const serviceBreakdown = [];
    const characterPromises = [];
    
    // Process each character in the text
    for (const char of text) {
      characterPromises.push(
        callCharacterService(char, style).then(result => {
          serviceBreakdown.push({
            name: `${result.serviceType}-service-${char}`,
            time: result.processingTime,
            success: result.success
          });
          return result.imageData;
        })
      );
    }
    
    // Wait for all character services to complete
    const characterImages = await Promise.all(characterPromises);
    
    // Call the image compositor service
    const compositorResult = await callImageCompositorService(characterImages);
    
    serviceBreakdown.push({
      name: 'image-compositor-service',
      time: compositorResult.processingTime,
      success: compositorResult.success
    });
    
    const totalTime = Date.now() - startTime;
    
    res.json({
      imageUrl: compositorResult.imageData,
      metrics: {
        totalTime,
        servicesUsed: serviceBreakdown.length,
        charactersProcessed: text.length,
        serviceBreakdown,
        overallSuccess: serviceBreakdown.every(service => service.success)
      }
    });
  } catch (error) {
    logger.error({ error: error.message }, 'Error generating image');
    res.status(500).json({ error: 'Failed to generate image' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start the server
app.listen(PORT, () => {
  logger.info(`Orchestrator service running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});
