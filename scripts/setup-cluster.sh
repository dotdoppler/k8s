#!/bin/bash
# ==========================================
# 搭建本地 K8s 测试集群 (针对 Mac 用户)
# 工具选择: minikube 或 kind (Kubernetes in Docker)
# ==========================================

echo "开始检查本地依赖环境..."

# 1. 检查 Docker 是否已安装并运行
if ! command -v docker &> /dev/null; then
    echo "[错误] Docker 未安装。请先安装 Docker Desktop for Mac。"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "[错误] Docker 未运行。请启动 Docker。"
    exit 1
fi
echo "[OK] Docker 运行正常。"

# 2. 检查并安装 Minikube
if ! command -v minikube &> /dev/null; then
    echo "[提示] 检测到未安装 minikube，正在使用 Homebrew 安装..."
    if command -v brew &> /dev/null; then
        brew install minikube
    else
        echo "[错误] Homebrew 未安装，无法自动安装 minikube。"
        exit 1
    fi
fi
echo "[OK] Minikube 可用。"

# 3. 检查 kubectl
if ! command -v kubectl &> /dev/null; then
    echo "[提示] 检测到未安装 kubectl，正在安装..."
    brew install kubectl
fi
echo "[OK] kubectl 可用。"

# 4. 启动 Minikube 集群
# 调整 CPU 和内存限制以适应 Java 编译和运行
echo "正在启动 Minikube 集群 (配置: 4 CPU, 4g Memory)..."
minikube start --cpus=4 --memory=4096 --driver=docker

# 5. 验证集群状态
echo "=========================================="
echo "集群状态验证："
kubectl get nodes
echo "=========================================="
echo "🎉 Minikube 集群搭建成功！"
echo "你可以通过运行 'minikube dashboard' 来查看 Web UI。"
echo "如果你需要使用本地 Docker 镜像，只需在终端中先执行: eval $(minikube docker-env)"
