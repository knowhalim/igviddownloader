import os
import shutil
import logging
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime

logger = logging.getLogger(__name__)

def cleanup_downloads():
    """
    Delete all downloaded videos to save space
    """
    try:
        downloads_dir = "igdownloader/downloads"
        
        if not os.path.exists(downloads_dir):
            logger.warning(f"Downloads directory does not exist: {downloads_dir}")
            return
            
        # Get all subdirectories in the downloads directory
        subdirs = [os.path.join(downloads_dir, d) for d in os.listdir(downloads_dir) 
                  if os.path.isdir(os.path.join(downloads_dir, d))]
        
        if not subdirs:
            logger.info("No downloads to clean up")
            return
            
        # Delete each subdirectory
        for subdir in subdirs:
            try:
                shutil.rmtree(subdir)
                logger.info(f"Deleted download directory: {subdir}")
            except Exception as e:
                logger.error(f"Error deleting directory {subdir}: {str(e)}")
                
        logger.info(f"Cleanup completed at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
    except Exception as e:
        logger.error(f"Error during cleanup: {str(e)}")

def setup_cleanup_scheduler():
    """
    Setup scheduler to clean up downloads at 3am, 9am, 3pm, and 9pm
    """
    scheduler = BackgroundScheduler()
    
    # Schedule cleanup at 3am, 9am, 3pm, and 9pm
    scheduler.add_job(cleanup_downloads, 'cron', hour='3,9,15,21', minute=0)
    
    # Start the scheduler
    scheduler.start()
    
    logger.info("Cleanup scheduler started")
    return scheduler
