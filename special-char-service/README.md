# Special Character Service

This service generates images for special characters (space, punctuation, etc.).

## Implementation

The special character service:

1. Receives a request with a character and styling parameters
2. Generates an image of the special character with the specified styling
3. Returns the image data

## Service Structure

```
special-char-service/
├── Dockerfile
├── package.json
├── src/
│   ├── index.js
│   └── characters/
│       ├── space.js
│       ├── period.js
│       ├── comma.js
│       └── ...
└── tests/
```

## API

### Generate Special Character Image

```
POST /generate
```

Request body:
```json
{
  "character": ".",
  "style": {
    "fontFamily": "Arial",
    "fontSize": 72,
    "fontWeight": "bold",
    "color": "#000000",
    "backgroundColor": "#FFFFFF",
    "effects": ["shadow", "outline"]
  }
}
```

Response:
```json
{
  "image": "base64-encoded-image-data",
  "format": "png",
  "width": 200,
  "height": 200
}
```

### List Supported Characters

```
GET /characters
```

Response:
```json
{
  "characters": [" ", ".", ",", "!", "?", "-", "_", "@", "#", "$", "%", "&", "*", "(", ")", "+", "=", "/", "\\", "|", "<", ">", "[", "]", "{", "}", ":", ";", "'", "\""]
}
```

### Health Check

```
GET /health
```

Response:
```json
{
  "status": "ok",
  "version": "0.1.0",
  "supportedCharacters": 30
}
```

## Implementation Guidelines

1. Use the same base image as letter and number services
2. Implement proper error handling
3. Add health check endpoint
4. Include logging
5. Add metrics collection points
6. Write unit tests
