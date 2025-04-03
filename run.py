#!/usr/bin/env python3
import os
import sys

# Add the parent directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Import the Flask app
from app import app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=2500)
