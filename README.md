# Instagram Video Downloader API

A Flask-based API service for downloading Instagram videos.

## Features

- Download Instagram videos via API
- Automatic cleanup of downloaded videos every 6 hours (3am, 9am, 3pm, 9pm)
- Simple API endpoints for downloading and retrieving videos
- Easy deployment to any server with a single script

## Quick Start


### Development Mode

Run the application in development mode:

```bash
chmod +x igdownloader/deploy.sh
./igdownloader/deploy.sh
```

### Production Mode

Deploy the application in production mode with Nginx and systemd:

```bash
chmod +x igdownloader/deploy.sh
./igdownloader/deploy.sh --production
```

This will:
- Install necessary system dependencies
- Set up a Python virtual environment
- Install all required Python packages
- Configure Nginx as a reverse proxy
- Set up a systemd service for automatic startup
- Configure basic firewall rules
- Optionally set up a domain name with SSL/HTTPS

During the deployment, you'll be prompted to:
1. Specify if you want to use a domain name
2. Enter your domain name
3. Configure DNS records (the script will show you the necessary settings)
4. Optionally set up SSL/HTTPS for your domain

## API Endpoints

### Download a Video

**Endpoint:** `POST /api/download`

**Request Body:**
```json
{
    "url": "https://www.instagram.com/p/SHORTCODE/"
}
```

**Response:**
```json
{
    "success": true,
    "download_id": "uuid-string",
    "message": "Video downloaded successfully"
}
```

### Get a Downloaded Video

**Endpoint:** `GET /api/video/<download_id>`

This endpoint returns the video file directly.

### Check Service Status

**Endpoint:** `GET /api/status`

**Response:**
```json
{
    "status": "online",
    "service": "Instagram Video Downloader API"
}
```

## Authentication

By default, this service doesn't use Instagram authentication. If you need to download private content, you'll need to modify the `downloader.py` file to include login credentials:

```python
# In the download_instagram_video function, after creating the Instaloader instance:
L.login(username, password)  # Replace with your Instagram credentials
```

## Automatic Cleanup

The service automatically cleans up downloaded videos at 3am, 9am, 3pm, and 9pm to save disk space.

## Troubleshooting

### Logs

- Application logs: `igdownloader/logs/app.log`
- For production mode: `sudo journalctl -u igdownloader`

### Common Issues

1. **Port already in use**: Change the port in `igdownloader/run.py`
2. **Permission denied**: Make sure you have the necessary permissions or run with sudo
3. **Instagram rate limiting**: Consider adding authentication or reducing request frequency

## License

This project is licensed under the MIT License - see the LICENSE file for details.
