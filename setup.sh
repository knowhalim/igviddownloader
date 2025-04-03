#!/bin/bash

# Create necessary directories
mkdir -p igdownloader/downloads
mkdir -p igdownloader/logs

# Install dependencies
pip3 install -r igdownloader/requirements.txt

echo "Setup completed. You can now run the application with:"
echo "python3 igdownloader/run.py"
