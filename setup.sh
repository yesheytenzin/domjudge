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

echo "=== Setting judgehost password ==="
docker exec domserver /opt/domjudge/domserver/webapp/bin/console domjudge:reset-user-password judgehost "$JUDGEDAEMON_PASSWORD"

echo "=== Starting judgehost (with cgroupns=host for cgroups support) ==="
docker rm -f judgehost-0 2>/dev/null || true
docker run -d \
	--name judgehost-0 \
	--restart unless-stopped \
	--privileged \
	--cgroupns=host \
	--hostname judgedaemon-0 \
	--network domjudge_default \
	-e DAEMON_ID=0 \
	-e CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE} \
	-e DOMSERVER_BASEURL=http://domserver/ \
	-e JUDGEDAEMON_USERNAME=judgehost \
	-e JUDGEDAEMON_PASSWORD=${JUDGEDAEMON_PASSWORD} \
	-v /sys/fs/cgroup:/sys/fs/cgroup \
	domjudge/judgehost:latest

echo ""
echo "=== DOMjudge Setup Complete ==="
echo "Admin URL:          http://localhost"
echo "Admin Username:     admin"
echo "Admin Password:     $ADMIN_PASSWORD"
echo "Judgehost Password: $JUDGEDAEMON_PASSWORD"
echo ""
echo "Judgehost is starting, check status with: docker logs -f judgehost-0"
