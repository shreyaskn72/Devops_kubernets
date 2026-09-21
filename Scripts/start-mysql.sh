#!/bin/bash

set -e

echo "Checking if MySQL volume exists..."

# Create volume if it doesn't exist
docker volume inspect mysql_data > /dev/null 2>&1 || docker volume create mysql_data

echo "MySQL volume ready."
echo ""

# Check if container is already running
if docker ps --format '{{.Names}}' | grep -q '^local-mysql$'; then
    echo "MySQL container is already running. Skipping startup."
    echo ""
else
    # Check if container exists but is stopped
    if docker ps -a --format '{{.Names}}' | grep -q '^local-mysql$'; then
        echo "Removing existing stopped MySQL container..."
        docker rm local-mysql
    fi

    echo "Starting MySQL container..."

    docker run -d \
      --name local-mysql \
      --restart unless-stopped \
      -e MYSQL_ROOT_PASSWORD=rootpassword \
      -e MYSQL_DATABASE=flask_app \
      -e MYSQL_USER=flask_user \
      -e MYSQL_PASSWORD=flask_password \
      -p 3306:3306 \
      -v mysql_data:/var/lib/mysql \
      mysql:8.0

    echo "Waiting for MySQL to be ready..."
    sleep 10

    # Check if MySQL is responding
    for i in {1..30}; do
        if docker exec local-mysql mysqladmin ping -uroot -prootpassword > /dev/null 2>&1; then
            echo "MySQL is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "Timeout waiting for MySQL to be ready"
            exit 1
        fi
        echo "Waiting... ($i/30)"
        sleep 1
    done
fi

echo "Ensuring MySQL application user can connect from Docker/Kubernetes..."
docker exec local-mysql mysql -uroot -prootpassword -e "
  CREATE USER IF NOT EXISTS 'flask_user'@'localhost' IDENTIFIED BY 'flask_password';
  CREATE USER IF NOT EXISTS 'flask_user'@'%' IDENTIFIED BY 'flask_password';
  ALTER USER 'flask_user'@'localhost' IDENTIFIED BY 'flask_password';
  ALTER USER 'flask_user'@'%' IDENTIFIED BY 'flask_password';
  GRANT ALL PRIVILEGES ON flask_app.* TO 'flask_user'@'localhost';
  GRANT ALL PRIVILEGES ON flask_app.* TO 'flask_user'@'%';
  FLUSH PRIVILEGES;
"

echo ""
echo "MySQL connection details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Host:     localhost (Docker host)"
echo "Port:     3307"
echo "Root:     root / rootpassword"
echo "Database: flask_app"
echo "User:     flask_user / flask_password"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
