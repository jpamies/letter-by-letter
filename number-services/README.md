# Number Services

This directory contains the microservices for generating images of individual numbers (0-9).

## Implementation

Each number service follows the same pattern:

1. Receives a request with styling parameters
2. Generates an image of the number with the specified styling
3. Returns the image data

## Service Structure

Each number service should be implemented in its own directory:

```
number-services/
├── 0-service/
│   ├── Dockerfile
│   ├── package.json
│   ├── src/
│   │   └── index.js
│   └── tests/
├── 1-service/
│   ├── ...
...
└── 9-service/
    └── ...
```

## API

Each service should implement the following API:

### Generate Number Image

```
POST /generate
```

Request body:
```json
{
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

### Health Check

```
GET /health
```

Response:
```json
{
  "status": "ok",
  "version": "0.1.0",
  "number": "5"
}
```

## Implementation Guidelines

1. Use a consistent base image for all services
2. Implement proper error handling
3. Add health check endpoint
4. Include logging
5. Add metrics collection points
6. Write unit tests
