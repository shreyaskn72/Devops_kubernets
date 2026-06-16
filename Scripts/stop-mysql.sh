#!/bin/bash

set -e

echo "Stopping MySQL container..."

if docker ps --format '{{.Names}}' | grep -q '^local-mysql$'; then
    docker stop local-mysql
    echo "MySQL container stopped."
else
    echo "MySQL container is not running."
fi

echo ""
echo "Note: MySQL data persists in the 'mysql_data' volume."
echo "To remove the volume and all data, run:"
echo "docker volume rm mysql_data"
echo ""
