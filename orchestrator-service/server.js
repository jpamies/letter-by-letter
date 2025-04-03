const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const pino = require('pino');
const pinoHttp = require('pino-http');

const app = express();
const PORT = process.env.PORT || 3000;

// Configure logger with more detailed output
const logger = pino({
  level: process.env.LOG_LEVEL || 'debug', // Set to debug for more verbose logging
  formatters: {
    level: (label) => {
      return { level: label };
    }
  },
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname'
    }
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(pinoHttp({ 
  logger,
  // Log all request bodies
  serializers: {
    req: (req) => ({
      id: req.id,
      method: req.method,
      url: req.url,
      body: req.raw.body,
      headers: req.headers
    })
  }
}));

// Service discovery configuration
// In a production environment, this would use service discovery (e.g., Kubernetes DNS)
// For local development, we use environment variables or defaults
const getServiceUrl = (serviceType, char) => {
  let serviceUrl;
  
  if (serviceType === 'letter') {
    // For letters A-Z
    serviceUrl = process.env.LETTER_SERVICE_URL || 'http://letter-service:3000';
  } else if (serviceType === 'number') {
    // For numbers 0-9
    serviceUrl = process.env.NUMBER_SERVICE_URL || 'http://number-service:3000';
  } else if (serviceType === 'special') {
    // For special characters
    serviceUrl = process.env.SPECIAL_CHAR_SERVICE_URL || 'http://special-char-service:3000';
  } else if (serviceType === 'compositor') {
    // For image compositor
    serviceUrl = process.env.COMPOSITOR_URL || 'http://compositor:3000';
  } else {
    throw new Error(`Unknown service type: ${serviceType}`);
  }
  
  logger.debug({ serviceType, serviceUrl }, 'Resolved service URL');
  return serviceUrl;
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

// Check if a service is available
const checkServiceHealth = async (serviceUrl) => {
  try {
    logger.debug({ serviceUrl }, 'Checking service health');
    const response = await axios.get(`${serviceUrl}/health`, { timeout: 2000 });
    return response.status === 200;
  } catch (error) {
    logger.warn({ serviceUrl, error: error.message }, 'Service health check failed');
    return false;
  }
};

// Call the appropriate service for a character
const callCharacterService = async (char, style = 'default') => {
  const serviceType = getServiceTypeForChar(char);
  const serviceUrl = getServiceUrl(serviceType);
  const startTime = Date.now();
  
  // Check if service is healthy before making the call
  const isHealthy = await checkServiceHealth(serviceUrl);
  if (!isHealthy) {
    logger.warn({ serviceType, serviceUrl }, 'Service is not healthy, skipping call');
    return {
      imageData: generateFallbackImage(char),
      processingTime: Date.now() - startTime,
      serviceType,
      success: false,
      error: 'Service health check failed'
    };
  }
  
  try {
    let requestBody = {};
    if (serviceType === 'letter') {
      requestBody = { letter: char, style };
    } else if (serviceType === 'number') {
      requestBody = { number: char, style };
    } else {
      requestBody = { character: char, style };
    }
    
    logger.info({ 
      char, 
      serviceType, 
      serviceUrl, 
      requestBody 
    }, 'Calling character service');
    
    const response = await axios.post(`${serviceUrl}/generate`, requestBody, {
      responseType: 'arraybuffer',
      timeout: 5000, // 5 second timeout
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'image/png'
      }
    });
    
    const processingTime = Date.now() - startTime;
    
    logger.info({ 
      char, 
      serviceType, 
      statusCode: response.status,
      responseSize: response.data.length,
      processingTime 
    }, 'Character service call successful');
    
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
    const processingTime = Date.now() - startTime;
    
    // Enhanced error logging with more details
    logger.error({ 
      char, 
      serviceType, 
      serviceUrl,
      processingTime,
      errorCode: error.code,
      errorMessage: error.message,
      errorResponse: error.response ? {
        status: error.response.status,
        statusText: error.response.statusText,
        headers: error.response.headers,
        data: error.response.data ? 'Binary data' : null
      } : 'No response',
      errorRequest: error.request ? {
        method: error.config.method,
        url: error.config.url,
        headers: error.config.headers
      } : 'No request'
    }, 'Error calling character service');
    
    // Generate a fallback image for the character
    return {
      imageData: generateFallbackImage(char),
      processingTime,
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
const callImageCompositorService = async (images, options = {}) => {
  try {
    const compositorUrl = getServiceUrl('compositor');
    const startTime = Date.now();
    
    logger.info({ compositorUrl, imageCount: images.length }, 'Calling image compositor service');
    
    // Check if compositor service is healthy
    const isHealthy = await checkServiceHealth(compositorUrl);
    if (!isHealthy) {
      logger.warn({ compositorUrl }, 'Compositor service is not healthy');
      throw new Error('Compositor service health check failed');
    }
    
    // Call the real compositor service with the new API
    const response = await axios.post(`${compositorUrl}/composite`, {
      images,
      options: {
        spacing: options.spacing || 5,
        backgroundColor: options.backgroundColor || '#ffffff',
        maxHeight: options.maxHeight || 200,
        padding: options.padding || 20,
        format: options.format || 'png'
      }
    }, {
      timeout: 10000, // 10 second timeout
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const processingTime = Date.now() - startTime;
    logger.info({ 
      processingTime,
      statusCode: response.status,
      responseSize: JSON.stringify(response.data).length
    }, 'Image compositor service call successful');
    
    return {
      imageData: response.data.compositeImage,
      processingTime,
      success: true
    };
  } catch (error) {
    logger.error({ 
      error: error.message,
      stack: error.stack,
      errorResponse: error.response ? {
        status: error.response.status,
        statusText: error.response.statusText,
        data: error.response.data
      } : 'No response'
    }, 'Error calling image compositor service');
    
    // Create a fallback composite image
    const fallbackComposite = createFallbackComposite(images);
    
    return {
      imageData: fallbackComposite,
      processingTime: 0,
      success: false,
      error: error.message
    };
  }
};

// Create a fallback composite image if the compositor service fails
const createFallbackComposite = (images) => {
  // Simple SVG fallback that places images side by side
  const svgWidth = images.length * 200;
  const svgContent = `
    <svg xmlns="http://www.w3.org/2000/svg" width="${svgWidth}" height="200">
      <rect width="${svgWidth}" height="200" fill="#ffffcc" />
      <text x="50%" y="20" dominant-baseline="middle" text-anchor="middle" font-size="16" fill="#cc6600">Fallback Composite</text>
      ${images.map((img, i) => `
        <image href="${img}" x="${i * 200}" y="30" width="180" height="160" />
      `).join('')}
    </svg>
  `;
  
  return `data:image/svg+xml;base64,${Buffer.from(svgContent).toString('base64')}`;
};

// Route to generate image from text
app.post('/generate', async (req, res) => {
  const requestId = req.id;
  try {
    const { text, style = 'default', compositorOptions = {} } = req.body;
    
    logger.info({ requestId, text, style, compositorOptions }, 'Received generate request');
    
    if (!text) {
      logger.warn({ requestId }, 'Missing text parameter');
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
            success: result.success,
            error: result.error
          });
          return result.imageData;
        })
      );
    }
    
    // Wait for all character services to complete
    const characterImages = await Promise.all(characterPromises);
    
    // Call the image compositor service with the new implementation
    const compositorResult = await callImageCompositorService(characterImages, compositorOptions);
    
    serviceBreakdown.push({
      name: 'compositor-service',
      time: compositorResult.processingTime,
      success: compositorResult.success,
      error: compositorResult.error
    });
    
    const totalTime = Date.now() - startTime;
    
    // Log success/failure statistics
    const successCount = serviceBreakdown.filter(s => s.success).length;
    const failureCount = serviceBreakdown.filter(s => !s.success).length;
    
    logger.info({ 
      requestId,
      totalTime,
      servicesCount: serviceBreakdown.length,
      successCount,
      failureCount,
      overallSuccess: failureCount === 0
    }, 'Request completed');
    
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
    logger.error({ 
      requestId,
      error: error.message,
      stack: error.stack 
    }, 'Error generating image');
    
    res.status(500).json({ error: 'Failed to generate image' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  // Check if we can connect to our dependencies
  logger.debug('Health check requested');
  res.status(200).json({ 
    status: 'ok',
    version: process.env.VERSION || '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Debug endpoint to check service URLs
app.get('/debug/services', (req, res) => {
  const services = {
    letter: getServiceUrl('letter'),
    number: getServiceUrl('number'),
    special: getServiceUrl('special'),
    compositor: getServiceUrl('compositor')
  };
  
  logger.debug({ services }, 'Service URLs');
  res.json(services);
});

// Start the server
app.listen(PORT, () => {
  logger.info(`Orchestrator service running on port ${PORT}`);
  
  // Log the service URLs on startup
  logger.info({
    letterServiceUrl: getServiceUrl('letter'),
    numberServiceUrl: getServiceUrl('number'),
    specialCharServiceUrl: getServiceUrl('special'),
    compositorServiceUrl: getServiceUrl('compositor')
  }, 'Service URLs');
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
