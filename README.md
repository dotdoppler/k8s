# 🚀 Kubernetes 云原生微服务进阶实战 (Java 后端专属)

这是为 Java 后端开发者量身打造的 **Kubernetes (K8s) 从入门到架构进阶实战** 学习开源项目。本项目摒弃了枯燥的运维概念，全程以 Spring Boot 微服务落地为核心视角，通过理论讲解结合本地集群 (`Minikube`) 多版本滚动升级实操，带领大家彻底打通云原生的任督二脉。

## 📁 核心目录指南

```text
.
├── docs/                 # 📚 核心知识库 (架构解析、避坑指南、组件对比)
│   ├── 00-路线图.md
│   ├── 01-基础概念.md
│   ├── 02-实战部署.md
│   ├── 03-配置管理.md
│   ├── 04-网关与路由.md
│   ├── 05-存储与持久化.md
│   ├── 06-Java微服务最佳实践.md
│   ├── 07-微服务服务发现与Feign.md
│   └── 08-SpringCloud与K8s微服务组件对比.md
├── apps/                 # 💻 Java 实战源码
│   └── demo-service/     # 极简版 Spring Boot 演示服务 (含 Actuator Probes / JDK17)
├── manifests/            # 📦 Kubernetes 部署配置清单 (按演进阶段划分)
│   ├── basic/            # V1: 基础 Pod / Deployment / Service
│   ├── config/           # V2: 配置外置化 ConfigMap 注入 (热更新)
│   ├── advanced/         # 高阶: Ingress 域名路由 / 网关暴露
│   └── best-practices/   # V3: 生产级 (JVM 内存约束 Limits / 存活与就绪探针探针)
└── scripts/              # 🛠 一键实操脚本 (支持本地平滑重放)
    ├── setup-cluster.sh       # 初始化搭建本地 Minikube 集群
    ├── deploy-demo.sh         # 一键发布 V1: 纯享版 Java 服务
    ├── deploy-config-demo.sh  # 一键发布 V2: 挂载外部配置的更新演示
    ├── deploy-ingress.sh      # 一键发布 Ingress Nginx 路由绑定
    └── deploy-prod.sh         # 一键发布 V3: 带全链路健康拨测的无损微服务发布
```

## 🎯 亮点与痛点解决

在本项目中，我们不仅实操了从 Docker 到集群的转换，还深入剖析了以下架构师视角的痛点问题：
- **K8s ConfigMap vs Nacos**：为何我们需要双轨制？(见 [03-配置管理](docs/03-配置管理.md))
- **Mac 502 Bad Gateway 劫持**：本地微服务环境网络冲突之终极排错。(见 [04-网关与路由](docs/04-网关与路由.md))
- **无注册中心的跨语言调用**：为何在 K8s 里用 Feign 可以完全抛弃 Ribbon 和 Nacos？(见 [07-服务发现](docs/07-微服务服务发现与Feign.md))
- **极限拉扯的底层对决**：Spring Cloud 传统组件被 K8s 哪些底层技术所“降维打击”替换？(见 [08-组件对比](docs/08-SpringCloud与K8s微服务组件对比.md))
- **OOMKilled 克星**：Java JVM (`-Xmx`) 与 K8s Cgroups Limit 的内存限制配合。

## 🚀 快速开始

1. 环境依赖：你的 Mac / Windows / Linux 机器必须安装并且运行着 `Docker`。
2. 进入终端并克隆本仓库到本地，并在项目根目录下执行：
    ```bash
    chmod +x scripts/setup-cluster.sh
    ./scripts/setup-cluster.sh
    ```
3. 按照 `docs` 目录下的 Markdown 顺序，一边阅读理论实战，一边执行对应的 `./scripts/deploy-xxx.sh` 脚本进行演练。

## ✒️ 写在最后
真正的架构师永远是在成本、安全与性能的“三角博弈”中做 Trade-Off。拥抱 Kubernetes 并不是为了盲目抛弃 Spring Cloud 的业务控制力，而是让**基础设施的事情回归基础设施，业务代码回归纯粹**！
