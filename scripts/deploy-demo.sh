#!/bin/bash
# ==========================================
# 部署 Demo Spring Boot 服务到 Minikube
# ==========================================

# 让脚本在遇到错误时退出
set -e

# 获取当前脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "1. 切换到 Minikube 的 Docker 环境..."
# 这一步非常关键：它使得我们在 Mac 终端执行的 docker build 是直接在 minikube 虚拟机里构建的
eval $(minikube docker-env)

echo "2. 构建 Java 服务的 Docker 镜像 (使用多阶段构建，这可能需要两到三分钟)..."
cd "$PROJECT_ROOT/apps/demo-service"
docker build -t dev/demo-service:v1 .

echo "3. 部署 K8s 资源..."
cd "$PROJECT_ROOT/manifests/basic"
kubectl apply -f demo-deployment.yaml
kubectl apply -f demo-service.yaml

echo "4. 检查部署状态..."
kubectl get pods -l app=demo-service
kubectl get svc demo-service

echo "=========================================="
echo "🎉 部署命令已下发！"
echo "应用可能还在启动中 (ContainerCreating)，你可以通过以下命令观察 Pod 状态："
echo "kubectl get pods -w"
echo ""
echo "待 Pod 状态均为 Running 后，有两种访问方式："
echo "1. 直接运行 'minikube service demo-service' (会自动打开浏览器)"
echo "2. (仅限 Linux 或有直接路由机制的主机): 分配给虚拟机的 Node IP 访问 'http://<minikube-ip>:30080/hello'"
echo "   ⚠️ 注意：在 Mac/Windows 上，由于 Docker 虚拟网络隔离，<minikube-ip> 不能直接在宿主机浏览器访问，"
echo "           请使用第一种方式 minikube service 会自动为您打通隧道代理 (port-forward)！"
echo "=========================================="
