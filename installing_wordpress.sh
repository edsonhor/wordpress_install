#!/bin/bash

# Exit on error
set -e

# installing packages 

sudo apt update
sudo apt install apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mariadb-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip

# installing Wordpress
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

# Define the path for the Apache config file
apache_conf="/etc/apache2/sites-available/wordpress.conf"

# Create the configuration file
echo "Creating Apache configuration file at $apache_conf..."
sudo tee $apache_conf > /dev/null <<EOL
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOL

echo "Configuration file created."

# Enable the site with:
sudo a2ensite wordpress
# Enable URL rewriting with:

sudo a2enmod rewrite
# Disable the default “It Works” site with:

sudo a2dissite 000-default

#reloading apache
sudo service apache2 reload


# Define variables (replace these with your desired values)
db_name="wordpress"              # WordPress database name
db_user="wordpress"              # WordPress database user
db_password="your-password"      # WordPress user password
mariadb_root_pw="root-password"  # Root password for MariaDB/MySQL

# Run MySQL commands to create the database and user
echo "Creating WordPress database and user..."

sudo mysql -u root -p$mariadb_root_pw <<MYSQL_SCRIPT
CREATE DATABASE $db_name;
CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER
    ON $db_name.*
    TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

echo "Database and user created successfully."

# Configure WordPress to connect to the database
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php

# Update wp-config.php with database details
echo "Updating wp-config.php..."

sudo -u www-data sed -i "s/database_name_here/$db_name/" "$wp_config_path"
sudo -u www-data sed -i "s/username_here/$db_user/" "$wp_config_path"
sudo -u www-data sed -i "s/password_here/$db_password/" "$wp_config_path"

echo "wp-config.php updated successfully."

 Define the path for the wp-config.php file
wp_config_path="/srv/www/wordpress/wp-config.php"

# Authentication keys and salts
auth_keys_salts=$(cat <<EOL
define('AUTH_KEY',         'n0VFP<#YZrRY8}lQ![[|bjRFJ/ 7#(aSAk*BIfukkf|K{u<GO8Yv$V/|cP#=Q9W+');
define('SECURE_AUTH_KEY',  '|;$f$++=uZ=u55NdDirwf/=i2NYA-arCm.0DhN8k5;K{m#mU+6C#<bfV %|x}p{]');
define('LOGGED_IN_KEY',    'sG?8.pede6O=C%SC4.x{6vNdOSZ$1A-nb]K)?^dA_K[q@OkU!WzS> |e7`O`0M2K');
define('NONCE_KEY',        'D> G *y+]{,m(qR!4UbDPA5b*Wf[}6UtmBmvq7]LO`@iK#SFry|0jH?F>LN Ndfo');
define('AUTH_SALT',        'BzEGJ(q$+9jxYE]Hq]3hhJLuH3xA@>1Sz+qZ]3n@!x*SgI- ssTEU:q}Ze|D73&0');
define('SECURE_AUTH_SALT', '7aGp&ZCbNatx}~dbKS$^zJsd&vU*3DR-U>QG`|#A_aTQ|O;bcO3rt~N9l(G<%-eM');
define('LOGGED_IN_SALT',   '2ZuGo|jQymUL]e/Q4:zMj<gZ-5a0W;84%fa xg?K#<$Ju_l4 E$hnG+vXUsk|.pO');
define('NONCE_SALT',       '0[YqWejN9v]4X|O?pVu.z=WK$-Je[uCjNU;-j=6Q;}.|M?3_d{hkydz|+P5_hi#4');
EOL
)

# Update wp-config.php with authentication keys and salts
echo "Updating wp-config.php with authentication keys and salts..."

# Backup the original wp-config.php
sudo cp "$wp_config_path" "$wp_config_path.bak"

# Append the keys and salts to wp-config.php
echo "$auth_keys_salts" | sudo -u www-data tee -a "$wp_config_path" > /dev/null

echo "wp-config.php updated successfully."
