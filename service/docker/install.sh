#!/bin/bash
set -e

# Configuration
IMAGE_NAME="melezh-server"
CONTAINER_NAME="melezh-app"
PORT=8080

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "X Docker is not installed. Please install Docker first."
    exit 1
fi

echo "V Docker is installed."

# Build the image
echo "O Building Docker image..."
docker build --no-cache -t "$IMAGE_NAME" .

# Check if container exists
if [ "$(docker ps -a -f "name=$CONTAINER_NAME" --format "{{.Status}}")" ]; then
    echo "I Container '$CONTAINER_NAME' already exists."
    read -p "Do you want to remove it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "O Removing old container..."
        docker stop "$CONTAINER_NAME" || true
        docker rm "$CONTAINER_NAME" || true
    else
        echo "I Skipped removal. Exiting."
        exit 0
    fi
fi

# Run new container
echo "V Running container on port $PORT..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$PORT:$PORT" \
  "$IMAGE_NAME"

# Done
echo
echo "V Server is running!"
echo "- Open in browser: http://localhost:$PORT"
echo "- Logs: docker logs $CONTAINER_NAME"