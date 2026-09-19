chmod +x Scripts/*.sh
cd Scripts
bash ./start-mysql.sh

# retry start-argocd up to 3 times
set +e
try=0
max=3
ok=0
until [ $try -ge $max ]; do
  bash ./start-argocd.sh && { ok=1; break; } || {
    try=$((try+1))
    echo "start-argocd attempt $try/$max failed"
    sleep 5
  }
done
set -e
if [ $ok -ne 1 ]; then
  echo "start-argocd failed after $max attempts"
  exit 1
fi

kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s

bash ./start-rabbitmq.sh
kubectl wait --for=condition=Available deployment --all -n messaging --timeout=300s

if helm status redis -n cache >/dev/null 2>&1; then
  kubectl wait --for=condition=Ready pods --all -n cache --timeout=300s
else
  bash ./start-redis.sh
fi

until bash ./start_frontend_backend_celery_flower.sh; do
  echo "Application resources are still being created; retrying in 10 seconds..."
  sleep 10
done


echo ""
echo ""
echo "========================================="
echo "run ./port-forward-all.sh inside Scripts folder to start port-forwarding"
echo "========================================="

