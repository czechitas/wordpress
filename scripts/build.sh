#!/bin/bash 

SITE_PATH="./public/wordpress.czechitas.online"
mkdir -p "$SITE_PATH"
echo "<html><body><h1>Welcome to wordpress.czechitas.online</h1></body></html>" > "$SITE_PATH/index.html"
curl -sS -L -A "Mozilla/5.0" -o "$SITE_PATH/adminer.php" https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
wp --allow-root core download --path=./wordpress --locale=cs_CZ --version=6.6.2

# Loop through the config.txt file line by line
while IFS=';' read -r WP_SERVER WP_TITLE WP_ADMIN_USER WP_ADMIN_EMAIL; do
  # Skip empty lines or lines starting with a comment
  if [[ -z "$WP_SERVER" || "$WP_SERVER" == \#* ]]; then
    continue
  fi

  echo "Bulding up site: $WP_SERVER"
  SITE_PATH="./public/$WP_SERVER"
  mkdir -p "$SITE_PATH"
  echo "<html><body><h1>Welcome to $WP_SERVER</h1></body></html>" > "$SITE_PATH/index.html"
done < ./config.txt
