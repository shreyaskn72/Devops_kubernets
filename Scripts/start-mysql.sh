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

    # Check that MySQL is accepting authenticated queries.
    for i in {1..30}; do
        if docker exec local-mysql mysql -uroot -prootpassword -e 'SELECT 1' > /dev/null 2>&1 || \
           docker exec local-mysql mysql -uflask_user -pflask_password flask_app -e 'SELECT 1' > /dev/null 2>&1; then
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

MYSQL_ADMIN_USER=""
if docker exec local-mysql mysql -uroot -prootpassword -e 'SELECT 1' > /dev/null 2>&1; then
    MYSQL_ADMIN_USER="root"
elif docker exec local-mysql mysql -uflask_user -pflask_password flask_app -e 'SELECT 1' > /dev/null 2>&1; then
    echo "Configured root password does not match the existing mysql_data volume."
    echo "Using the existing flask_user account; the database volume was preserved."
    MYSQL_ADMIN_USER="flask_user"
else
    echo "MySQL is running, but neither the configured root nor application credentials work."
    echo "Remove the mysql_data volume only if its data is no longer needed, then retry."
    exit 1
fi

if [ "$MYSQL_ADMIN_USER" = "root" ]; then
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
fi

echo ""
echo "MySQL connection details:"
echo "---------------------------------------------------"
echo "Host:     localhost (Docker host)"
echo "Port:     3306"
echo "Root:     root / rootpassword (new volume only)"
echo "Database: flask_app"
echo "User:     flask_user / flask_password"
echo "---------------------------------------------------"
echo ""
