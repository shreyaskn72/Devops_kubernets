chmod +x Scripts/*.sh
cd Scripts

./stop-mysql.sh
./stop-argocd.sh
./stop-rabbitmq.sh
./stop-redis.sh
./stop-backend-frontend-celery-flower.sh