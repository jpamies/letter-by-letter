# Image Compositor Service

This service is responsible for compositing multiple character images into a single image for the Letter-by-Letter Image Generator application.

## Features

- **Image Composition**: Combines multiple images into a single composite image with customizable spacing and layout
- **Text-to-Image Conversion**: Creates images from text with customizable fonts and styles
- **Image Effects**: Applies visual effects like blur, grayscale, rotation, and brightness/contrast adjustments
- **Structured Logging**: Uses Pino for efficient, JSON-based logging
- **Health Monitoring**: Provides a health check endpoint for monitoring

## API Endpoints

### Composite Images

```
POST /composite
```

Combines multiple images into a single composite image.

**Request Body:**
```json
{
  "images": [
    "data:image/png;base64,...",
    "data:image/png;base64,...",
    "..."
  ],
  "options": {
    "spacing": 5,
    "backgroundColor": "#ffffff",
    "maxHeight": 200,
    "padding": 20,
    "format": "png"
  }
}
```

**Response:**
```json
{
  "compositeImage": "data:image/png;base64,..."
}
```

### Text to Image

```
POST /text-to-image
```

Creates an image from text.

**Request Body:**
```json
{
  "text": "Hello World",
  "options": {
    "fontFamily": "Arial, sans-serif",
    "fontSize": 48,
    "fontColor": "#000000",
    "backgroundColor": "#ffffff",
    "padding": 20,
    "format": "png"
  }
}
```

**Response:**
```json
{
  "textImage": "data:image/png;base64,..."
}
```

### Apply Effects

```
POST /apply-effects
```

Applies visual effects to an image.

**Request Body:**
```json
{
  "image": "data:image/png;base64,...",
  "effects": {
    "blur": 0,
    "grayscale": false,
    "rotate": 0,
    "brightness": 1,
    "contrast": 1,
    "format": "png"
  }
}
```

**Response:**
```json
{
  "processedImage": "data:image/png;base64,..."
}
```

### Health Check

```
GET /health
```

Returns the health status of the service.

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-04-03T13:34:31.000Z"
}
```

## Local Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the service:
   ```bash
   npm start
   ```

3. For development with auto-reload:
   ```bash
   npm run dev
   ```

## Environment Variables

- `PORT`: The port the service will listen on (default: 3000)
- `LOG_LEVEL`: Logging level (default: 'info')
- `VERSION`: Service version (default: '1.0.0')

## Dependencies

- Express: Web framework
- Sharp: Image processing library
- Canvas: HTML5 canvas implementation for Node.js
- Pino: Structured logging
- CORS: Cross-origin resource sharing middleware
- Body-parser: Request body parsing middleware
