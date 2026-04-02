#!/bin/bash
set -e

set -a
source .env
set +a

echo "=== Starting MariaDB and DOMserver ==="
docker compose up -d mariadb domserver

echo "=== Waiting for DOMserver to initialize (60s) ==="
sleep 60

echo "=== Setting admin password ==="
docker exec domserver /opt/domjudge/domserver/webapp/bin/console domjudge:reset-user-password admin "$ADMIN_PASSWORD"

echo "=== Starting all containers (including judgehosts) ==="
docker compose up -d

echo ""
echo "=== DOMjudge Setup Complete ==="
echo "Admin URL:          http://localhost:8080"
echo "Admin Username:     admin"
echo "Admin Password:     $ADMIN_PASSWORD"
echo "Judgehost Password: $JUDGEDAEMON_PASSWORD"
