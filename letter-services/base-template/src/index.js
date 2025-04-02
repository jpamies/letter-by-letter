const express = require('express');
const { createCanvas } = require('canvas');
const pino = require('pino');
const pinoHttp = require('pino-http');

// Configuration
const PORT = process.env.PORT || 3000;
const LETTER = process.env.LETTER || 'A';
const VERSION = process.env.VERSION || '0.1.0';

// Create logger
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
});

// Create Express app
const app = express();

// Add logging middleware
app.use(pinoHttp({ logger }));

// Parse JSON bodies
app.use(express.json());

// Generate letter image
app.post('/generate', (req, res) => {
  try {
    const style = req.body.style || {};
    
    // Set default style values
    const fontFamily = style.fontFamily || 'Arial';
    const fontSize = style.fontSize || 72;
    const fontWeight = style.fontWeight || 'bold';
    const color = style.color || '#000000';
    const backgroundColor = style.backgroundColor || '#FFFFFF';
    const effects = style.effects || [];
    
    // Create canvas
    const canvas = createCanvas(200, 200);
    const ctx = canvas.getContext('2d');
    
    // Fill background
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, 200, 200);
    
    // Configure font
    ctx.font = `${fontWeight} ${fontSize}px ${fontFamily}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    // Apply effects
    if (effects.includes('shadow')) {
      ctx.shadowColor = 'rgba(0, 0, 0, 0.5)';
      ctx.shadowBlur = 5;
      ctx.shadowOffsetX = 3;
      ctx.shadowOffsetY = 3;
    }
    
    // Draw letter
    ctx.fillStyle = color;
    ctx.fillText(LETTER, 100, 100);
    
    // Apply outline effect if requested
    if (effects.includes('outline')) {
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 2;
      ctx.strokeText(LETTER, 100, 100);
    }
    
    // Convert to PNG
    const imageData = canvas.toDataURL('image/png').split(',')[1];
    
    // Return image data
    res.json({
      image: imageData,
      format: 'png',
      width: 200,
      height: 200
    });
    
    logger.info(`Generated image for letter ${LETTER}`);
  } catch (error) {
    logger.error({ error }, `Error generating image for letter ${LETTER}`);
    res.status(500).json({ error: 'Failed to generate image' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    version: VERSION,
    letter: LETTER
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Letter service for "${LETTER}" listening on port ${PORT}`);
});
