const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pino = require('pino');
const pinoHttp = require('pino-http');
const { compositeImages, createTextImage, applyEffects } = require('./imageProcessor');

// Configure logger
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  timestamp: pino.stdTimeFunctions.isoTime
});
const httpLogger = pinoHttp({ logger });

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(httpLogger);

// Route to composite images
app.post('/composite', async (req, res) => {
  try {
    const { images, options } = req.body;
    
    if (!images || !Array.isArray(images) || images.length === 0) {
      logger.warn('Invalid request: Missing or empty images array');
      return res.status(400).json({ error: 'Valid images array is required' });
    }
    
    logger.info(`Processing composite request with ${images.length} images`);
    
    // Use the imageProcessor to composite the images
    const compositeImage = await compositeImages(images, options);
    
    logger.info('Successfully composited images');
    res.json({ compositeImage });
  } catch (error) {
    logger.error({ err: error }, 'Error compositing images');
    res.status(500).json({ error: 'Failed to composite images', details: error.message });
  }
});

// Route to create text image
app.post('/text-to-image', async (req, res) => {
  try {
    const { text, options } = req.body;
    
    if (!text || typeof text !== 'string') {
      logger.warn('Invalid request: Missing or invalid text');
      return res.status(400).json({ error: 'Valid text string is required' });
    }
    
    logger.info(`Creating text image for: "${text.substring(0, 20)}${text.length > 20 ? '...' : ''}"`);
    
    // Create an image from the text
    const textImage = await createTextImage(text, options);
    
    logger.info('Successfully created text image');
    res.json({ textImage });
  } catch (error) {
    logger.error({ err: error }, 'Error creating text image');
    res.status(500).json({ error: 'Failed to create text image', details: error.message });
  }
});

// Route to apply effects to an image
app.post('/apply-effects', async (req, res) => {
  try {
    const { image, effects } = req.body;
    
    if (!image || typeof image !== 'string') {
      logger.warn('Invalid request: Missing or invalid image');
      return res.status(400).json({ error: 'Valid image data is required' });
    }
    
    logger.info('Processing image effects request');
    
    // Apply effects to the image
    const processedImage = await applyEffects(image, effects);
    
    logger.info('Successfully applied effects to image');
    res.json({ processedImage });
  } catch (error) {
    logger.error({ err: error }, 'Error applying effects to image');
    res.status(500).json({ error: 'Failed to apply effects', details: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    version: process.env.VERSION || '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error({ err }, 'Unhandled error');
  res.status(500).json({ error: 'Internal server error', details: err.message });
});

// Start the server
app.listen(PORT, () => {
  logger.info(`Image compositor service running on port ${PORT}`);
});
