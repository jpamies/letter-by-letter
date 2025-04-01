# Letter-by-Letter Image Generator for EKS AutoMode Demo

This application demonstrates EKS AutoMode capabilities by generating images of text using microservices for each letter and number.

## Architecture

- **Frontend**: React application for user input and displaying results
- **Orchestrator Service**: Coordinates requests to letter/number services
- **Letter Services (A-Z)**: Generate images for each letter
- **Number Services (0-9)**: Generate images for each digit
- **Special Character Service**: Handles spaces, punctuation, etc.
- **Image Compositor Service**: Assembles the final image

## Development Stages

1. **First Iteration**: Frontend, Orchestrator, and Image Compositor with mocked letter services
2. **Second Iteration**: Implement actual letter, number, and special character services
3. **Third Iteration**: Add metrics, tracing, and visualization components
4. **Final Stage**: Deploy to EKS with AutoMode configuration

## Getting Started

Each component has its own directory with instructions for running locally:

- **frontend/**: React application for user interface
- **orchestrator-service/**: Service that coordinates requests
- **image-compositor-service/**: Service that assembles the final image
- **letter-services/**: Directory containing services for each letter
- **number-services/**: Directory containing services for each digit
- **special-char-service/**: Service for special characters

## Deployment

The application is deployed using AWS services:

- **Container Registry**: Images are stored in Amazon ECR
- **Kubernetes**: Services run on Amazon EKS with AutoMode
- **CI/CD**: Automated build and deployment configured in AWS console

## Local Development

To run the services locally:

1. Navigate to the service directory
2. Follow the README instructions in each component directory
3. Use Docker Compose for local orchestration

## Contributing

Please see the CONTRIBUTING.md file for guidelines on how to contribute to this project.
