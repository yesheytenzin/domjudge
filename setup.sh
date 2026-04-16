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

echo "=== Starting 3 judgehosts (with cgroupns=host for cgroups support) ==="
for i in 0 1 2; do
	docker rm -f judgehost-$i 2>/dev/null || true
	docker run -d \
		--name judgehost-$i \
		--restart unless-stopped \
		--privileged \
		--cgroupns=host \
		--hostname judgedaemon-$i \
		--network domjudge_default \
		-e DAEMON_ID=$i \
		-e CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE} \
		-e DOMSERVER_BASEURL=http://domserver/ \
		-e JUDGEDAEMON_USERNAME=judgehost \
		-e JUDGEDAEMON_PASSWORD=${JUDGEDAEMON_PASSWORD} \
		-v /sys/fs/cgroup:/sys/fs/cgroup \
		domjudge/judgehost:latest
done

echo ""
echo "=== DOMjudge Setup Complete ==="
echo "Admin URL:          http://localhost"
echo "Admin Username:     admin"
echo "Admin Password:     $ADMIN_PASSWORD"
echo "Judgehost Password: $JUDGEDAEMON_PASSWORD"
echo ""
echo "Judgehosts are starting, check status with:"
echo "  docker logs -f judgehost-0"
echo "  docker logs -f judgehost-1"
echo "  docker logs -f judgehost-2"
