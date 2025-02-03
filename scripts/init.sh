#!/bin/bash

# Default values
CZECHITAS_USER="czechitas"
CZECHITAS_EMAIL="wordpress@czechitas.cz"
CONFIG_FILE="/var/www/config.txt"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file '$CONFIG_FILE' not found!"
  exit 1
fi

# Loop through the config.txt file line by line
while IFS=';' read -r WP_HOST WP_SERVER WP_TITLE WP_ADMIN_USER WP_ADMIN_EMAIL; do
  # Skip empty lines or lines starting with a comment
  if [[ -z "$WP_HOST" || "$WP_HOST" == "#"* ]]; then
    continue
  fi

  # Skip entries that do not match the current WP_HOSTNAME
  if [[ "$WP_HOST" != "$WP_HOSTNAME" ]]; then
    continue
  fi

  # Validate that all necessary fields are provided
  if [ -z "$WP_SERVER" ] || [ -z "$WP_TITLE" ] || [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
    echo "Warning: Skipping line with missing fields"
    continue
  fi

  # Check if the environment variables for the passwords exist
  if [ -z "$ADMIN_PASSWORD" ] || [ -z "$CZECHITAS_PASSWORD" ]; then
    echo "Error: Missing passwords"
    continue
  fi

  # Extract WP_SITE from the subdomain (e.g., wp01 from wp01.wordpress.czechitas.online)
  WP_SITE=$(echo "$WP_SERVER" | cut -d'.' -f1)
  echo "Setting up site: $WP_SITE"

  # Check if the database exists
  if ! mysql -u"$WP_DB_USER" -p"$WP_DB_PASSWORD" -h"$WP_DB_HOST" -e "SHOW DATABASES LIKE '$WP_SITE';" | grep -q "$WP_SITE"; then
    echo "Creating database: $WP_SITE"
    mysql -u"$WP_DB_USER" -p"$WP_DB_PASSWORD" -h"$WP_DB_HOST" -e "CREATE DATABASE \`$WP_SITE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
  else
    echo "Database $WP_SITE already exists. Skipping."
  fi

  # Define the new site path
  SITE_PATH="/var/www/public/$WP_SERVER"

  if [ ! -d "$SITE_PATH" ]; then
    mkdir -p "$SITE_PATH"
    echo "Copying WordPress files to $SITE_PATH"
    cp -R /var/www/wordpress/* "$SITE_PATH/"
    sed "s/PLACEHOLDER_DB_NAME/$WP_SITE/g" /var/www/wp-config.php > "$SITE_PATH/wp-config.php"
  fi

  # Install WordPress if it's not already installed
  if ! wp core is-installed --path="$SITE_PATH"; then
    echo "Installing WordPress for $WP_SITE"
    wp core install --path="$SITE_PATH" --url="https://$WP_SERVER" --title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --allow-root
    
    # Create the user for Czechitas
    wp user create --path="$SITE_PATH" "$CZECHITAS_USER" "$CZECHITAS_EMAIL" --role=administrator --user_pass="$CZECHITAS_PASSWORD" --allow-root
    echo "WordPress installation and Czechitas user creation completed for $WP_SITE"
  else
    echo "WordPress is already installed for $WP_SITE."
  fi
done < "$CONFIG_FILE"
