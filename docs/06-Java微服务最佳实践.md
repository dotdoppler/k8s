# 06-Java微服务最佳实践：容器化调优与高可用探针

如果我们只是把 Java 应用塞进镜像然后 `kubectl apply`，那算不上真正的云原生架构。这节课我们将解决两个极其普遍的痛点：**OOM (Out Of Memory) 杀虫剂** 和 **假死服务隔离 (Health Check)**。

## 1. 资源限制与 JVM 堆内存的爱恨情仇 (Requests & Limits)
在 K8s 中，通过 `resources` 可以对运行的容器设定 CPU 和内存的限制：
- **Requests** (乞丐版下限)：向调度器宣告 "我至少需要 512M 内存才能跑"，K8s 会帮你找一个有 512M 空闲的 Node 放进去。
- **Limits** (土豪版上限)：运行时最高不能超过 1GB，一旦进程触碰这条红线，操作系统的 OOMKiller 会无情地 `kill -9` 杀掉你的容器，状态变为 `OOMKilled`。

**致命陷阱（Java 8 老版本的痛）**：
以前 JVM 看不到容器的 limit，它只会读取物理机的 32GB 内存。如果你给了它 `-Xmx16G`，但 Pod 的 limit 只有 2G。JVM 沾沾自喜分配内存，瞬间超过 2G 被 K8s 秒杀。
**最佳实践**：
好在 Java 11/17+ 已经内置了容器感知 (`-XX:+UseContainerSupport` 默认开启)，我们只需要配好 `limits`，JVM 就会自动把 `-Xmx` 设置为 Limit 的 1/4（或者通过 `-XX:MaxRAMPercentage=75.0` 显式设置利用率，极其推荐）。

## 2. Spring Boot Actuator 与 K8s 探针的双剑合璧
一个 Pod 状态变成了 `Running` 并不代表你的 Spring 服务可以接客了，它可能还在初始化数据库连接池。如果你这时候把流量导过去，用户就会收到 502。
K8s 提供了三个核心探针（Probes）：

1. **Startup Probe (启动探针)**："别催我，我在启动！" (如果一直不成功就重启，成功后交接给下面两位)。
2. **Readiness Probe (就绪探针)**："我准备好了，把 Service 的流量发给我吧！" (如果失败了，K8s 会把你从 Service 的 Endpoint 列表里摘除，流量不再进来)。
3. **Liveness Probe (存活探针)**："哥们还活着，别杀我！" (如果你的应用死锁或者内存死循环了，此探针会失败，K8s 判定你假死了，直接把你干掉重启)。

Spring Boot 2.3+ 提供了一键集成：只要开启了 `management.endpoint.health.probes.enabled=true`，应用就会自动暴露 `/actuator/health/liveness` 和 `/actuator/health/readiness` 供 K8s 拨测！

---
**📝 练习提示：**
我已为您配置了符合上述最佳实践的 V3 版本 Deployment。
运行 `./scripts/deploy-prod.sh` 后，你可以仔细观察 `demo-deployment-prod.yaml` 中的 `resources` 声明和探针配置。部署完成后，新旧替换的 Rolling Update 会变得非常丝滑（旧 Pod 绝不会在你的新 Pod 真正就绪前被干掉）！
