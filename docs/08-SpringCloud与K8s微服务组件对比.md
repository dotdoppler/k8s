# 08-架构师内功：Spring Cloud 传统微服务与 Kubernetes 底层组件对比

很多从传统 Java 体系向云原生体系过渡的开发者，都会经历一段阵痛期：**到底是继续用全家桶，还是把组件剥离给基础设施（K8s）？**

其实，微服务的核心诉求（服务发现、负载均衡、配置中心、网关隔离）在 K8s 中都有非常优雅的原生实现。它们之间的区别，在于**在应用层代码（Java）里解决，还是在系统内核网络层（Linux/iptables）解决**。

---

## 核心组件一一映射对比表

| 微服务领域诉求 | 传统 Spring Cloud 组件 | K8s 原生替代组件 / 生态 | 解耦层级 |
|--------------|---------------------|------------------------|---------|
| **服务注册与发现** | Eureka / Nacos / Consul | **CoreDNS + Service (Endpoint)** | L4 基础设施层 |
| **负载均衡** | Ribbon / SC-LoadBalancer | **Kube-proxy (iptables/IPVS)** | L4 操作系统内核层 |
| **API 网关** | Zuul / SC-Gateway | **Ingress (Nginx/Traefik)** | L7 基础设施代理层 |
| **配置中心** | Nacos / Apollo / SC-Config | **ConfigMap / Secret** | 容器环境/文件挂载层 |
| **熔断与限流** | Sentinel / Hystrix / Resilience4j | **Service Mesh (Istio Envoy)** | L7 Sidecar 代理层 |
| **定时任务** | XXL-Job / Quartz / ElasticJob| **Job / CronJob** | K8s 原生调度系统 |

---

## 深度原理解析：为什么 K8s 能替代它们？

### 1. 服务注册与发现 (Nacos vs K8s CoreDNS)
- **传统原理**：`demo-service` A 启动时，带着自己的 IP 注册到 Nacos。`caller-service` B 启动时，去 Nacos 把 A 的 IP 列表拉到 Java 内存里保存。
- **K8s 原理**：当你创建了一个 K8s Service，API Server 会立刻命令 `CoreDNS` 内部 DNS 服务器为你注册一个短域名（例如 `demo-service`）。当后端的 Pod (Java 进程) 根据水平扩容增减生灭时，K8s 控制面会自动把它对应的 IP 塞进 `Endpoints` 列表里。
- **优点**：极端的跨语言。你不必引入体积庞大的 Nacos/Eureka 客户端依赖包。

### 2. 负载均衡 (Ribbon vs Kube-proxy)
- **传统原理**：客户端负载均衡 (Client-Side LB)。你的代码从 Nacos 拿到 3 个 IP，Ribbon 在自己进程里算一下轮询算法（比如 Round-Robin），挑出 `10.0.0.1`，然后发出 HTTP 请求。
- **K8s 原理**：服务端负载均衡 (Server-Side LB)。Java 程序只向 K8s 短域名发起普通调用：`http://demo-service:8080/hello`。这个请求刚出网卡，就被节点上的守护进程 `kube-proxy` 设下的底层 `iptables` 规则拦截了。Linux 内核把网络包的目标 IP 直接随机/轮转改成那 3 个健康后端 Pod 的真实 IP 之一。
- **优点**：没有任何业务侵入，彻底释放 JVM 的内存压力。

### 3. API 网关 (Gateway vs Ingress)
- **传统原理**：SC-Gateway 本质上就是一个监听 80 端口的高并发 Netty / WebFlux 进程。所有外网请求打入服务器，它通过自己的路由规则解析并用网卡再转手发起一次 HTTP 请求。
- **K8s 原理**：Ingress 背后跑着 Nginx Ingress Controller 进程。当你在 K8s 里提交了 Ingress YAML 规则，Controller 在后台实时 Watch 到了规则变动，立刻在 C 语言层面上修改 `nginx.conf` 并 `nginx -s reload`。
- **选型建议**：如果你的网关仅仅用来做**纯路由分发和 SSL 卸载**，用 Ingress 就足够了。但如果网关承载了**大量自定义 Java 鉴权逻辑、黑白名单或数据清洗**，保留 SC-Gateway 作为 Ingress 后面的第一层服务，依然是业界主流。

### 4. 熔断降级限流 (Sentinel vs Istio)
- **传统原理**：在 Java 代码的方法上加 `@SentinelResource` 注解，由 AOP 统计并发请求数或者 QPS，超过阈值抛出 BlockException。
- **K8s 高阶形态 (Service Mesh / Istio)**：Java 代码像平时一样随手 `restTemplate.get()`，完全不顾死活也不加任何重试。在同一 Pod 里面，K8s 偷偷为你开了一个拦截所有网络出口的 Sidecar 边车进程（Envoy）。Envoy 看到这个请求，它默默帮你做了 3 次重试；如果对端报错率超过 50%，Envoy 默默切断并直接向 Java 甩回一个 503 熔断响应。
- **优点**：真正实现了业务代码只关心业务。开发人员不需要研究降级算法，由 SRE 运维人员统一管理重试/熔断策略。
