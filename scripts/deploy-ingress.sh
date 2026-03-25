#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "1. 在 Minikube 中开启 Ingress 插件 (Nginx Controller)..."
# 注意：这可能会花上 1~2 分钟下载 Nginx 反代镜像并启动 Controller
minikube addons enable ingress

echo "2. 部署 Ingress 路由规则..."
kubectl apply -f "$PROJECT_ROOT/manifests/advanced/demo-ingress.yaml"

echo "=========================================="
echo "🎉 Ingress 部署完成！"
echo "为了能在宿主机访问，请注意以下关键操作："
echo ""
echo "在 Linux 上，你只需在 /etc/hosts 添加 '<minikube-ip> demo.local.com' 即可访问。"
echo ""
echo "但在 Mac 系统上，由于 Docker 隔离，你需要建立一个隧道代理："
echo "请新开一个终端窗口，执行并保持运行："
echo "   minikube tunnel"
echo ""
echo "然后，修改你本机的 /etc/hosts 文件，添加一条记录："
echo "   127.0.0.1 demo.local.com"
echo ""
echo "配置完成后，即可在浏览器直接访问: http://demo.local.com/hello"
echo "=========================================="
