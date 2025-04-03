const express = require('express');
const { createCanvas } = require('canvas');
const cors = require('cors');
const pino = require('pino');
const pinoHttp = require('pino-http');

const app = express();
const port = process.env.PORT || 3000;

// Configure logger with more detailed output
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
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
app.use(express.json());
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

// Health check endpoint
app.get('/health', (req, res) => {
  logger.debug('Health check requested');
  res.status(200).json({ status: 'ok' });
});

// Generate special character image endpoint
app.post('/generate', (req, res) => {
  const requestId = req.id;
  try {
    logger.info({ requestId, body: req.body }, 'Generate special character image request received');
    
    const { character, style = 'default' } = req.body;
    
    if (!character || typeof character !== 'string' || character.length !== 1) {
      logger.warn({ requestId, character }, 'Invalid character parameter');
      return res.status(400).json({ error: 'Invalid character parameter. Must be a single character.' });
    }
    
    // Check if the character is a special character (not a letter or number)
    if (/^[a-zA-Z0-9]$/.test(character)) {
      logger.warn({ requestId, character }, 'Character is not a special character');
      return res.status(400).json({ error: 'Character must be a special character (not a letter or number)' });
    }
    
    // Generate the image
    logger.debug({ requestId, character, style }, 'Generating special character image');
    const startTime = Date.now();
    const imageBuffer = generateSpecialCharImage(character, style);
    const processingTime = Date.now() - startTime;
    
    // Add artificial delay to simulate processing time (optional)
    const artificialDelay = Math.floor(Math.random() * 200) + 100; // 100-300ms
    
    logger.info({ 
      requestId, 
      character, 
      style, 
      processingTime,
      artificialDelay,
      imageSize: imageBuffer.length
    }, 'Special character image generated');
    
    setTimeout(() => {
      res.set('Content-Type', 'image/png');
      res.send(imageBuffer);
    }, artificialDelay);
  } catch (error) {
    logger.error({ 
      requestId, 
      error: error.message,
      stack: error.stack 
    }, 'Error generating special character image');
    
    res.status(500).json({ error: 'Failed to generate special character image' });
  }
});

// Function to generate a special character image
function generateSpecialCharImage(character, style) {
  // Canvas size
  const width = 200;
  const height = 200;
  
  // Create canvas
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  
  // Fill background
  ctx.fillStyle = '#f8f8f8';
  ctx.fillRect(0, 0, width, height);
  
  // Apply style
  switch (style) {
    case 'bold':
      ctx.font = 'bold 120px Arial';
      ctx.fillStyle = '#000000';
      break;
    case 'colorful':
      ctx.font = '120px Arial';
      ctx.fillStyle = '#ff00ff';
      break;
    case 'shadow':
      ctx.font = '120px Arial';
      ctx.shadowColor = 'rgba(0, 0, 0, 0.5)';
      ctx.shadowBlur = 10;
      ctx.shadowOffsetX = 5;
      ctx.shadowOffsetY = 5;
      ctx.fillStyle = '#cc0000';
      break;
    case 'glow':
      ctx.font = '120px Arial';
      ctx.shadowColor = 'rgba(255, 255, 0, 0.8)';
      ctx.shadowBlur = 15;
      ctx.fillStyle = '#ffcc00';
      break;
    default:
      ctx.font = '120px Arial';
      ctx.fillStyle = '#333333';
  }
  
  // Handle space character specially
  if (character === ' ') {
    // Draw a visual representation for space
    ctx.fillStyle = '#dddddd';
    ctx.fillRect(50, 90, 100, 20);
    ctx.font = '24px Arial';
    ctx.fillStyle = '#666666';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('SPACE', width / 2, height / 2 + 40);
  } else {
    // Center the character
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(character, width / 2, height / 2);
  }
  
  // Add a decorative border for special characters
  ctx.strokeStyle = '#3366cc';
  ctx.lineWidth = 5;
  ctx.strokeRect(10, 10, width - 20, height - 20);
  
  // Return the image as a buffer
  return canvas.toBuffer('image/png');
}

// Start the server
app.listen(port, () => {
  logger.info(`Special character service listening on port ${port}`);
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
