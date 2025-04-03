import instaloader
import re
import os
import logging

logger = logging.getLogger(__name__)

def download_instagram_video(url, download_path):
    """
    Download a video from an Instagram post URL
    
    Args:
        url (str): Instagram post URL
        download_path (str): Path to save the downloaded video
    
    Returns:
        dict: Result of the download operation
    """
    try:
        # Create an instance of Instaloader with custom settings
        L = instaloader.Instaloader(
            dirname_pattern=download_path,
            download_videos=True,
            download_video_thumbnails=False,
            download_geotags=False,
            download_comments=False,
            save_metadata=False,
            post_metadata_txt_pattern="",
            compress_json=False
        )
        
        # Extract the shortcode from the URL
        shortcode_match = re.search(r'instagram.com/(?:p|reel|tv)/([^/?]+)', url)
        
        if not shortcode_match:
            logger.error(f"Could not extract post shortcode from URL: {url}")
            return {"success": False, "message": "Could not extract post shortcode from URL"}
            
        shortcode = shortcode_match.group(1)
        logger.info(f"Extracted shortcode: {shortcode} from URL: {url}")
        
        # Get post by shortcode
        post = instaloader.Post.from_shortcode(L.context, shortcode)
        
        # Check if the post contains a video
        if not post.is_video:
            logger.warning(f"The Instagram post does not contain a video: {url}")
            return {"success": False, "message": "The Instagram post does not contain a video"}
        
        # Download the video
        logger.info(f"Downloading video from post by {post.owner_username}...")
        L.download_post(post, target=None)
        
        logger.info(f"Video downloaded successfully to {download_path}")
        return {"success": True, "message": "Video downloaded successfully"}
        
    except instaloader.exceptions.InstaloaderException as e:
        logger.error(f"Instaloader error: {str(e)}")
        return {"success": False, "message": f"Instagram download error: {str(e)}"}
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {"success": False, "message": f"Unexpected error: {str(e)}"}
