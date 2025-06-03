#!/bin/bash

# Docker + Electron Startup Script
# This script starts Docker containers and then launches the Electron app

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Update these values for your setup
CONTAINER1_NAME="trait-back"
CONTAINER1_IMAGE="calebstew32/trait-back:1.1"  # Use your Docker Hub image
CONTAINER1_PORT="5174:5174"

CONTAINER2_NAME="trait-front"
CONTAINER2_IMAGE="calebstew32/trait-front:1.0"  # Use your Docker Hub image
CONTAINER2_PORT="5173:5173"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    print_status "Checking if Docker is running..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to ensure Docker images are available
ensure_images() {
    print_status "Ensuring Docker images are available..."
    
    # Docker will automatically pull images if they don't exist locally
    # when we run 'docker run', but we can also explicitly pull them
    
    print_status "Checking/pulling $CONTAINER1_IMAGE..."
    if ! docker image inspect $CONTAINER1_IMAGE > /dev/null 2>&1; then
        print_status "Pulling $CONTAINER1_IMAGE from Docker Hub..."
        docker pull $CONTAINER1_IMAGE
    fi
    print_success "$CONTAINER1_IMAGE is ready"
    
    print_status "Checking/pulling $CONTAINER2_IMAGE..."
    if ! docker image inspect $CONTAINER2_IMAGE > /dev/null 2>&1; then
        print_status "Pulling $CONTAINER2_IMAGE from Docker Hub..."
        docker pull $CONTAINER2_IMAGE
    fi
    print_success "$CONTAINER2_IMAGE is ready"
}
stop_existing_containers() {
    print_status "Stopping existing containers..."
    
    # Stop and remove container 1 if it exists (running or stopped)
    if docker ps -a -q -f name=$CONTAINER1_NAME | grep -q .; then
        print_status "Found existing $CONTAINER1_NAME container..."
        if docker ps -q -f name=$CONTAINER1_NAME | grep -q .; then
            print_status "Stopping running $CONTAINER1_NAME container..."
            docker stop $CONTAINER1_NAME
        fi
        print_status "Removing $CONTAINER1_NAME container..."
        docker rm $CONTAINER1_NAME || true
    fi
    
    # Stop and remove container 2 if it exists (running or stopped)
    if docker ps -a -q -f name=$CONTAINER2_NAME | grep -q .; then
        print_status "Found existing $CONTAINER2_NAME container..."
        if docker ps -q -f name=$CONTAINER2_NAME | grep -q .; then
            print_status "Stopping running $CONTAINER2_NAME container..."
            docker stop $CONTAINER2_NAME
        fi
        print_status "Removing $CONTAINER2_NAME container..."
        docker rm $CONTAINER2_NAME || true
    fi
}

# Function to start containers
start_containers() {
    print_status "Starting Docker containers..."
    
    # Start first container
    print_status "Starting $CONTAINER1_NAME..."
    docker run -d \
        --name $CONTAINER1_NAME \
        -p $CONTAINER1_PORT \
        $CONTAINER1_IMAGE
    
    # Wait a moment for first container to initialize
    sleep 2
    
    # Start second container
    print_status "Starting $CONTAINER2_NAME..."
    docker run -d \
        --name $CONTAINER2_NAME \
        -p $CONTAINER2_PORT \
        $CONTAINER2_IMAGE
    
    print_success "Containers started successfully"
}

# Function to wait for containers to be ready
wait_for_containers() {
    print_status "Waiting for containers to be ready..."
    
    # Wait for first container
    print_status "Checking $CONTAINER1_NAME health..."
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if curl -s http://127.0.0.1:5174/ > /dev/null 2>&1; then
            print_success "$CONTAINER1_NAME is ready"
            break
        fi
        
        if [ $retries -eq $((max_retries - 1)) ]; then
            print_warning "$CONTAINER1_NAME may not be fully ready yet, continuing anyway..."
            break
        fi
        
        print_status "Waiting for $CONTAINER1_NAME... (attempt $((retries + 1))/$max_retries)"
        sleep 2
        retries=$((retries + 1))
    done
    
    # Wait for second container
    print_status "Checking $CONTAINER2_NAME health..."
    retries=0
    
    while [ $retries -lt $max_retries ]; do
        if curl -s http://127.0.0.1:5173/ > /dev/null 2>&1; then
            print_success "$CONTAINER2_NAME is ready"
            break
        fi
        
        if [ $retries -eq $((max_retries - 1)) ]; then
            print_warning "$CONTAINER2_NAME may not be fully ready yet, continuing anyway..."
            break
        fi
        
        print_status "Waiting for $CONTAINER2_NAME... (attempt $((retries + 1))/$max_retries)"
        sleep 2
        retries=$((retries + 1))
    done
}

# Function to check if package.json exists
check_package_json() {
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in current directory"
        print_error "Please run this script from your Electron app directory"
        exit 1
    fi
    print_success "Found package.json"
}

# Function to install dependencies if needed
install_dependencies() {
    if [ ! -d "node_modules" ]; then
        print_status "node_modules not found, installing dependencies..."
        npm install
        print_success "Dependencies installed"
    else
        print_success "Dependencies already installed"
    fi
}

# Function to start Electron app
start_electron() {
    print_status "Starting Electron app..."
    
    # Check if electron script exists in package.json
    if npm run | grep -q "electron"; then
        npm run electron
    else
        print_error "No 'electron' script found in package.json"
        print_status "Available scripts:"
        npm run
        exit 1
    fi
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up..."
    print_status "Stopping containers..."
    docker stop $CONTAINER1_NAME 2>/dev/null || true
    docker stop $CONTAINER2_NAME 2>/dev/null || true
    print_success "Cleanup complete"
}

# Trap to cleanup on script exit
trap cleanup EXIT

# Main execution
main() {
    print_status "Starting Docker + Electron setup..."
    
    # Check prerequisites
    check_docker
    check_package_json
    
    # Ensure images are available
    ensure_images
    
    # Docker operations
    stop_existing_containers
    start_containers
    wait_for_containers
    
    # Electron operations
    install_dependencies
    start_electron
}

# Run main function
main "$@"