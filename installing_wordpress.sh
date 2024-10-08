#!/bin/bash

# Exit on error
set -e

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y

# Install Apache
echo "Installing Apache..."
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2

# Install MySQL
echo "Installing MySQL..."
sudo apt install mysql-server -y
sudo systemctl enable mysql
sudo systemctl start mysql

# Secure MySQL Installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation

# Create a WordPress Database
echo "Creating a WordPress database..."
read -p "Enter the WordPress database name: " wp_db
read -p "Enter the MySQL root password: " mysql_root_pw
read -p "Enter the WordPress database user: " wp_user
read -p "Enter the WordPress database user password: " wp_user_pw

sudo mysql -u root -p$mysql_root_pw <<MYSQL_SCRIPT
CREATE DATABASE $wp_db;
CREATE USER '$wp_user'@'localhost' IDENTIFIED BY '$wp_user_pw';
GRANT ALL PRIVILEGES ON $wp_db.* TO '$wp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

echo "WordPress database and user created."

# Install PHP and required extensions
echo "Installing PHP and required extensions..."
sudo apt install php libapache2-mod-php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc -y

# Download WordPress
echo "Downloading WordPress..."
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz

# Configure WordPress
echo "Configuring WordPress..."
sudo cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
sudo mkdir -p /var/www/html/wordpress
sudo cp -a /tmp/wordpress/. /var/www/html/wordpress/

# Set Permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/wordpress/
sudo chmod -R 755 /var/www/html/wordpress/

# Update wp-config.php with database details
sudo sed -i "s/database_name_here/$wp_db/g" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/username_here/$wp_user/g" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/password_here/$wp_user_pw/g" /var/www/html/wordpress/wp-config.php

# Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

echo "WordPress installation completed. You can now finish the setup by accessing your VM's IP in a browser."
