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

// Generate letter image endpoint
app.post('/generate', (req, res) => {
  const requestId = req.id;
  try {
    logger.info({ requestId, body: req.body }, 'Generate letter image request received');
    
    const { letter, style = 'default' } = req.body;
    
    if (!letter || typeof letter !== 'string' || letter.length !== 1) {
      logger.warn({ requestId, letter }, 'Invalid letter parameter');
      return res.status(400).json({ error: 'Invalid letter parameter. Must be a single character.' });
    }
    
    // Check if the letter is in A-Z range (case insensitive)
    const upperLetter = letter.toUpperCase();
    if (upperLetter < 'A' || upperLetter > 'Z') {
      logger.warn({ requestId, letter: upperLetter }, 'Character not in A-Z range');
      return res.status(400).json({ error: 'Character must be a letter (A-Z)' });
    }
    
    // Generate the image
    logger.debug({ requestId, letter: upperLetter, style }, 'Generating letter image');
    const startTime = Date.now();
    const imageBuffer = generateLetterImage(upperLetter, style);
    const processingTime = Date.now() - startTime;
    
    // Add artificial delay to simulate processing time (optional)
    const artificialDelay = Math.floor(Math.random() * 200) + 100; // 100-300ms
    
    logger.info({ 
      requestId, 
      letter: upperLetter, 
      style, 
      processingTime,
      artificialDelay,
      imageSize: imageBuffer.length
    }, 'Letter image generated');
    
    setTimeout(() => {
      res.set('Content-Type', 'image/png');
      res.send(imageBuffer);
    }, artificialDelay);
  } catch (error) {
    logger.error({ 
      requestId, 
      error: error.message,
      stack: error.stack 
    }, 'Error generating letter image');
    
    res.status(500).json({ error: 'Failed to generate letter image' });
  }
});

// Function to generate a letter image
function generateLetterImage(letter, style) {
  // Canvas size
  const width = 200;
  const height = 200;
  
  // Create canvas
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  
  // Fill background
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, width, height);
  
  // Apply style
  switch (style) {
    case 'bold':
      ctx.font = 'bold 120px Arial';
      ctx.fillStyle = '#000000';
      break;
    case 'italic':
      ctx.font = 'italic 120px Times New Roman';
      ctx.fillStyle = '#000080';
      break;
    case 'fancy':
      ctx.font = '120px Cursive';
      ctx.fillStyle = '#800080';
      break;
    case 'outline':
      ctx.font = '120px Arial';
      ctx.strokeStyle = '#ff0000';
      ctx.lineWidth = 2;
      break;
    default:
      ctx.font = '120px Arial';
      ctx.fillStyle = '#000000';
  }
  
  // Center the letter
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  
  // Draw the letter
  if (style === 'outline') {
    ctx.strokeText(letter, width / 2, height / 2);
  } else {
    ctx.fillText(letter, width / 2, height / 2);
  }
  
  // Add a border
  ctx.strokeStyle = '#cccccc';
  ctx.lineWidth = 5;
  ctx.strokeRect(10, 10, width - 20, height - 20);
  
  // Return the image as a buffer
  return canvas.toBuffer('image/png');
}

// Start the server
app.listen(port, () => {
  logger.info(`Letter service listening on port ${port}`);
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
