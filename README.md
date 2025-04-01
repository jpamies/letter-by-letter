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

Each component has its own directory with instructions for running locally.
