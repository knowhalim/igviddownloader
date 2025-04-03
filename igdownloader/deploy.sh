#!/bin/bash

# Instagram Downloader API Deployment Script
# This script sets up the Instagram Downloader API in either development or production mode

# Text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
    echo -e "${BLUE}==================================================${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install system dependencies
install_system_dependencies() {
    print_step "Installing system dependencies"
    
    if command_exists apt-get; then
        print_message "Detected Debian/Ubuntu system"
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv nginx
    elif command_exists yum; then
        print_message "Detected RHEL/CentOS system"
        sudo yum -y update
        sudo yum -y install python3 python3-pip nginx
    elif command_exists pacman; then
        print_message "Detected Arch Linux system"
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm python python-pip nginx
    else
        print_warning "Could not detect package manager. Please install Python 3, pip, and Nginx manually."
    fi
}

# Function to create and activate virtual environment
setup_virtual_environment() {
    print_step "Setting up Python virtual environment"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_message "Virtual environment created"
    else
        print_message "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install dependencies
    pip install -r igdownloader/requirements.txt
    
    # Install production dependencies if needed
    if [ "$DEPLOYMENT_MODE" == "production" ]; then
        pip install gunicorn
    fi
    
    print_message "Dependencies installed successfully"
}

# Function to create necessary directories
create_directories() {
    print_step "Creating necessary directories"
    
    mkdir -p igdownloader/downloads
    mkdir -p igdownloader/logs
    
    print_message "Directories created successfully"
}

# Function to set up systemd service for production
setup_systemd_service() {
    print_step "Setting up systemd service"
    
    # Get the current directory
    CURRENT_DIR=$(pwd)
    
    # Create systemd service file
    cat > igdownloader.service << EOF
[Unit]
Description=Instagram Downloader API
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$CURRENT_DIR
ExecStart=$CURRENT_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:2500 --chdir igdownloader app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # Move service file to systemd directory
    sudo mv igdownloader.service /etc/systemd/system/
    
    # Reload systemd, enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable igdownloader
    sudo systemctl start igdownloader
    
    print_message "Systemd service set up successfully"
}

# Function to set up Nginx as a reverse proxy
setup_nginx() {
    print_step "Setting up Nginx as a reverse proxy"
    
    # Prompt for domain name
    read -p "Do you want to use a domain name for this service? (y/n): " use_domain
    
    if [[ "$use_domain" =~ ^[Yy]$ ]]; then
        read -p "Enter your domain name (e.g., example.com): " domain_name
        
        # Get server IP
        server_ip=$(hostname -I | awk '{print $1}')
        
        print_message "Your server IP is: $server_ip"
        print_message "Please ensure your domain $domain_name points to this IP address."
        print_message "You need to update your DNS records with the following:"
        print_message "Type: A, Name: $domain_name, Value: $server_ip"
        
        read -p "Have you configured your DNS records? (y/n): " dns_configured
        
        if [[ "$dns_configured" =~ ^[Yy]$ ]]; then
            # Create Nginx configuration file with domain
            cat > igdownloader_nginx << EOF
server {
    listen 80;
    server_name $domain_name;

    location / {
        proxy_pass http://127.0.0.1:2500;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
            
            # Ask about SSL
            read -p "Do you want to set up SSL/HTTPS for your domain? (y/n): " setup_ssl
            
            if [[ "$setup_ssl" =~ ^[Yy]$ ]]; then
                # Check if certbot is installed
                if ! command_exists certbot; then
                    print_message "Installing certbot for SSL certificate..."
                    
                    if command_exists apt-get; then
                        sudo apt-get install -y certbot python3-certbot-nginx
                    elif command_exists yum; then
                        sudo yum -y install certbot python3-certbot-nginx
                    else
                        print_warning "Could not install certbot automatically. Please install it manually."
                    fi
                fi
                
                # Set up SSL with certbot
                if command_exists certbot; then
                    print_message "Setting up SSL certificate for $domain_name..."
                    sudo certbot --nginx -d $domain_name
                else
                    print_warning "Certbot not found. Please install it manually and run: sudo certbot --nginx -d $domain_name"
                fi
            fi
        else
            print_warning "Please configure your DNS records before continuing."
            print_message "You can still access the service using the server IP: $server_ip"
            
            # Create Nginx configuration file with server IP
            cat > igdownloader_nginx << EOF
server {
    listen 80;
    server_name $server_ip;

    location / {
        proxy_pass http://127.0.0.1:2500;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        fi
    else
        # Get server IP
        server_ip=$(hostname -I | awk '{print $1}')
        print_message "You can access the service using the server IP: $server_ip"
        
        # Create Nginx configuration file with default settings
        cat > igdownloader_nginx << EOF
server {
    listen 80;
    server_name _;  # Default server block

    location / {
        proxy_pass http://127.0.0.1:2500;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    fi
    
    # Move configuration file to Nginx directory
    if [ -d "/etc/nginx/sites-available" ]; then
        # Debian/Ubuntu style
        sudo mv igdownloader_nginx /etc/nginx/sites-available/igdownloader
        sudo ln -sf /etc/nginx/sites-available/igdownloader /etc/nginx/sites-enabled/
    else
        # RHEL/CentOS style
        sudo mv igdownloader_nginx /etc/nginx/conf.d/igdownloader.conf
    fi
    
    # Test Nginx configuration
    sudo nginx -t
    
    # Restart Nginx
    sudo systemctl restart nginx
    
    print_message "Nginx set up successfully"
}

# Function to set up firewall
setup_firewall() {
    print_step "Setting up firewall"
    
    if command_exists ufw; then
        # Ubuntu/Debian with UFW
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        print_message "UFW firewall configured"
    elif command_exists firewall-cmd; then
        # RHEL/CentOS with firewalld
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
        print_message "Firewalld configured"
    else
        print_warning "No supported firewall detected. Please configure your firewall manually."
    fi
}

# Function to run the application in development mode
run_development() {
    print_step "Starting application in development mode"
    
    # Activate virtual environment if not already activated
    if [ -z "$VIRTUAL_ENV" ]; then
        source venv/bin/activate
    fi
    
    # Run the application
    python3 igdownloader/run.py
}

# Main script execution
main() {
    print_step "Starting Instagram Downloader API deployment"
    
    # Check if Python 3 is installed
    if ! command_exists python3; then
        print_error "Python 3 is not installed. Please install it and try again."
        exit 1
    fi
    
    # Parse command line arguments
    DEPLOYMENT_MODE="development"
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --production) DEPLOYMENT_MODE="production" ;;
            --help) 
                echo "Usage: ./deploy.sh [--production]"
                echo ""
                echo "Options:"
                echo "  --production    Deploy in production mode with Nginx and systemd"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *) print_error "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
    
    print_message "Deployment mode: $DEPLOYMENT_MODE"
    
    # Create directories
    create_directories
    
    # Setup virtual environment
    setup_virtual_environment
    
    if [ "$DEPLOYMENT_MODE" == "production" ]; then
        # Install system dependencies
        install_system_dependencies
        
        # Setup systemd service
        setup_systemd_service
        
        # Setup Nginx
        setup_nginx
        
        # Setup firewall
        setup_firewall
        
        print_step "Production deployment completed"
        print_message "The Instagram Downloader API is now running as a service"
        
        # Get server IP
        server_ip=$(hostname -I | awk '{print $1}')
        
        if [[ "$use_domain" =~ ^[Yy]$ ]] && [[ "$dns_configured" =~ ^[Yy]$ ]]; then
            if [[ "$setup_ssl" =~ ^[Yy]$ ]]; then
                print_message "You can access it at: https://$domain_name/"
            else
                print_message "You can access it at: http://$domain_name/"
            fi
        else
            print_message "You can access it at: http://$server_ip/"
        fi
        
        print_message "To check the service status: sudo systemctl status igdownloader"
        print_message "To view logs: sudo journalctl -u igdownloader"
    else
        # Run in development mode
        run_development
    fi
}

# Execute main function
main "$@"
