from flask import Flask, request, jsonify, send_file
import os
from downloader import download_instagram_video
from cleanup import setup_cleanup_scheduler
import uuid
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("igdownloader/logs/app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Create directories if they don't exist
os.makedirs("igdownloader/downloads", exist_ok=True)
os.makedirs("igdownloader/logs", exist_ok=True)

# Setup the cleanup scheduler
setup_cleanup_scheduler()

@app.route('/api/download', methods=['POST'])
def download_video():
    """API endpoint to download Instagram videos"""
    try:
        data = request.get_json()
        
        if not data or 'url' not in data:
            return jsonify({"error": "URL is required"}), 400
            
        url = data['url']
        download_id = str(uuid.uuid4())
        download_path = os.path.join("igdownloader/downloads", download_id)
        
        # Create a directory for this download
        os.makedirs(download_path, exist_ok=True)
        
        # Download the video
        result = download_instagram_video(url, download_path)
        
        if not result['success']:
            return jsonify({"error": result['message']}), 400
            
        # Return the download ID and file path
        return jsonify({
            "success": True,
            "download_id": download_id,
            "message": "Video downloaded successfully"
        }), 200
        
    except Exception as e:
        logger.error(f"Error in download_video: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/video/<download_id>', methods=['GET'])
def get_video(download_id):
    """API endpoint to retrieve a downloaded video"""
    try:
        download_path = os.path.join("igdownloader/downloads", download_id)
        
        if not os.path.exists(download_path):
            return jsonify({"error": "Download not found"}), 404
            
        # Find the video file
        video_files = [f for f in os.listdir(download_path) if f.endswith(('.mp4', '.mov'))]
        
        if not video_files:
            return jsonify({"error": "Video file not found"}), 404
            
        video_path = os.path.join(download_path, video_files[0])
        
        # Send the file
        return send_file(video_path, as_attachment=True)
        
    except Exception as e:
        logger.error(f"Error in get_video: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/status', methods=['GET'])
def status():
    """API endpoint to check service status"""
    return jsonify({
        "status": "online",
        "service": "Instagram Video Downloader API"
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=2500, debug=False)
