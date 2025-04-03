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

// Generate number image endpoint
app.post('/generate', (req, res) => {
  const requestId = req.id;
  try {
    logger.info({ requestId, body: req.body }, 'Generate number image request received');
    
    const { number, style = 'default' } = req.body;
    
    if (number === undefined || number === null || number.toString().length !== 1) {
      logger.warn({ requestId, number }, 'Invalid number parameter');
      return res.status(400).json({ error: 'Invalid number parameter. Must be a single digit (0-9).' });
    }
    
    // Check if the number is in 0-9 range
    const digit = number.toString();
    if (!/^[0-9]$/.test(digit)) {
      logger.warn({ requestId, number: digit }, 'Character not in 0-9 range');
      return res.status(400).json({ error: 'Character must be a digit (0-9)' });
    }
    
    // Generate the image
    logger.debug({ requestId, number: digit, style }, 'Generating number image');
    const startTime = Date.now();
    const imageBuffer = generateNumberImage(digit, style);
    const processingTime = Date.now() - startTime;
    
    // Add artificial delay to simulate processing time (optional)
    const artificialDelay = Math.floor(Math.random() * 200) + 100; // 100-300ms
    
    logger.info({ 
      requestId, 
      number: digit, 
      style, 
      processingTime,
      artificialDelay,
      imageSize: imageBuffer.length
    }, 'Number image generated');
    
    setTimeout(() => {
      res.set('Content-Type', 'image/png');
      res.send(imageBuffer);
    }, artificialDelay);
  } catch (error) {
    logger.error({ 
      requestId, 
      error: error.message,
      stack: error.stack 
    }, 'Error generating number image');
    
    res.status(500).json({ error: 'Failed to generate number image' });
  }
});

// Function to generate a number image
function generateNumberImage(digit, style) {
  // Canvas size
  const width = 200;
  const height = 200;
  
  // Create canvas
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  
  // Fill background
  ctx.fillStyle = '#f0f0f0';
  ctx.fillRect(0, 0, width, height);
  
  // Apply style
  switch (style) {
    case 'bold':
      ctx.font = 'bold 120px Arial';
      ctx.fillStyle = '#000000';
      break;
    case 'digital':
      ctx.font = '120px "Courier New"';
      ctx.fillStyle = '#00ff00';
      break;
    case 'retro':
      ctx.font = '120px Impact';
      ctx.fillStyle = '#ff6600';
      break;
    case 'outline':
      ctx.font = '120px Arial';
      ctx.strokeStyle = '#0000ff';
      ctx.lineWidth = 2;
      break;
    default:
      ctx.font = '120px Arial';
      ctx.fillStyle = '#000000';
  }
  
  // Center the number
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  
  // Draw the number
  if (style === 'outline') {
    ctx.strokeText(digit, width / 2, height / 2);
  } else {
    ctx.fillText(digit, width / 2, height / 2);
  }
  
  // Add a border
  ctx.strokeStyle = '#aaaaaa';
  ctx.lineWidth = 5;
  ctx.strokeRect(10, 10, width - 20, height - 20);
  
  // Return the image as a buffer
  return canvas.toBuffer('image/png');
}

// Start the server
app.listen(port, () => {
  logger.info(`Number service listening on port ${port}`);
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
