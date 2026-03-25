#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "1. 部署持久卷声明 (PVC)..."
kubectl apply -f "$PROJECT_ROOT/manifests/storage/mysql-pv-pvc.yaml"

echo "   等待 StorageClass 自动提供后端存储卷 (动态 Provisioning) ..."
sleep 3

echo "2. 部署 MySQL 数据库及 Service ..."
kubectl apply -f "$PROJECT_ROOT/manifests/storage/mysql-deployment.yaml"

echo "=========================================="
echo "🎉 MySQL 部署请求已下发！"
echo "K8s 正在拉取体积较大的 mysql:8.0 镜像，这可能需要花费几分钟时间。"
echo "您可以执行以下命令持续观察状态："
echo "   kubectl get pods -w -l app=mysql"
echo "   kubectl get pvc mysql-pv-claim"
echo "=========================================="
