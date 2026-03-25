#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "1. 切换到 Minikube 环境..."
eval $(minikube docker-env)

echo "2. 构建 V3 版本 (带有 Actuator 健康检查端点)..."
cd "$PROJECT_ROOT/apps/demo-service"
docker build -t dev/demo-service:v3 .

echo "3. 部署生产级别 Deployment..."
cd "$PROJECT_ROOT/manifests/best-practices"
kubectl apply -f demo-deployment-prod.yaml

echo "4. 详细观察 K8s 的平滑升级策略 (Rolling Update)..."
echo "你会发现，新创建出来的 Pod 会一直处于不就绪状态 (0/1 READY)，直到它的 Readiness Probe (HTTP 请求 /actuator/health/readiness) 拨测返回 HTTP 200。"
echo "只有在拨测成功后，K8s 才会放心地去干掉旧的 V2 版本 Pod，在这个过程中，如果你在浏览器疯狂刷新业务，不会遇到一星半点儿的请求失败和停机！"
kubectl rollout status deployment/demo-service-deployment

echo "=========================================="
echo "🎉 生产级微服务部署完毕！"
echo "您可以执行 \`kubectl describe pod -l app=demo-service | grep -A 5 Liveness\` 检查探针设置情况。"
echo "=========================================="
