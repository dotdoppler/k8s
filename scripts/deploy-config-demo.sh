#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "1. 切换到 Minikube 的 Docker 环境..."
eval $(minikube docker-env)

echo "2. 构建 V2 版本的 Docker 镜像..."
cd "$PROJECT_ROOT/apps/demo-service"
docker build -t dev/demo-service:v2 .

echo "3. 部署 ConfigMap 与 Deployment (v2)..."
cd "$PROJECT_ROOT/manifests/config"
kubectl apply -f demo-configmap.yaml
# 我们保留了原本的 Service (不需要更新)，只需 apply 新的 deployment
kubectl apply -f demo-deployment-v2.yaml

echo "4. 检查滚动更新状态..."
kubectl rollout status deployment/demo-service-deployment
echo "=========================================="
echo "🎉 V2 版本部署完成！"
echo "你可以通过刷新浏览器或继续执行 curl 测试，看看输出信息是否从 'Hello from Kubernetes!' 变成了 ConfigMap 中的 'Hello from Kubernetes ConfigMap (Version 2)!'。"
echo "=========================================="
