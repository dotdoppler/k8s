# 07-打破注册中心依赖：K8s 原生服务发现与 Feign 通信

很多 Java 开发者初学 K8s 时最大的疑惑就是：**“既然 K8s 宣称自己能做服务治理，那我的 Nacos/Eureka 还要不要了？如果没有 Nacos，我的 Feign/RestTemplate 怎么知道别的服务在哪？”**

答案是：**在云原生架构中，K8s 自身就是最强大的注册中心。**

## 1. 概念对比：客户端负载均衡 vs 服务端负载均衡

### A. 传统 Spring Cloud 模式 (Nacos + Ribbon)
- **机制**：客户端负载均衡 (Client-Side LB)
- **流程**：
  1. `demo-service` (被调方) 启动，把自己的 IP `192.168.1.100` 注册回 Nacos。
  2. `caller-service` (调用方) 的 Ribbon 从 Nacos 同步地址列表。
  3. `caller-service` 的 Feign 直接向 `192.168.1.100` 发起真实 HTTP 请求。
- **痛点**：强依赖 Nacos 组件；非 Java 语言（如 Go/Python）要想混编，需要自己写一套 Nacos 客户端。

### B. K8s 原生模式 (CoreDNS + Service)
- **机制**：服务端负载均衡 (Server-Side LB)
- **流程**：
  1. K8s 会为每一个 `Service` 在内部 DNS 组件 (CoreDNS) 注册一个内部域名，比如 `demo-service.default.svc.cluster.local`（简写就是 `demo-service`）。
  2. `caller-service` (调用方) 的 Feign 直接把请求发给 `http://demo-service:8080`。
  3. 宿主机的网络层 (`kube-proxy` 控制的 iptables/IPVS) 会自动拦截这个请求，并在底层随机/轮询挑选一个 `demo-service` 后端 Pod 的真实 IP 发送过去。
- **优势**：绝对的跨语言！不管你是用 Java 的 Feign 还是 Python 的 requests，只要请求这个内部域名，K8s 底层帮你解决负载均衡。

## 2. K8s 下使用 Feign 的三种方案大比拼

### 方案一：硬刚 K8s DNS (无脑 Server-side LB) —— **推荐**
完全抛弃 Netflix Ribbon / Spring Cloud LoadBalancer。
代码写法：直接利用 `url` 属性指向 K8s Service 名字。
```java
// 因为不需要从注册中心找实例，直接指明 url
@FeignClient(name = "demo-service", url = "http://demo-service:8080")
public interface DemoFeignClient {
    @GetMapping("/hello")
    String getHello();
}
```

### 方案二：引入 Spring Cloud Kubernetes (融合路线)
如果你依然留恋 Ribbon/LoadBalancer 在客户端做重试、熔断的快感，可以引入 `spring-cloud-starter-kubernetes-discoveryclient`。
此时底层机制变为：你的 Java 服务会调用 K8s API Server 的接口（相当于把 K8s 当作 Nacos），拉取所有 Pod 的真实 IP，然后在 Java 进程内存里做轮询分发。
```java
@FeignClient(name = "demo-service") // 没有 url 参数，依赖 DiscoveryClient
public interface DemoFeignClient {
// ...
```

### 方案三：Service Mesh (终极云原生形态，如 Istio)
代码里的写法和方案一完全一样：
```java
@FeignClient(name = "demo-service", url = "http://demo-service:8080")
```
但在底层，K8s 会悄悄给你的应用旁边塞一个 Envoy Sidecar 代理。你的 HTTP 请求才刚出 Java 进程，就被旁边的 Envoy 劫持。Envoy 拥有比 K8s Service 强大百倍的七层路由能力（熔断、重试、看流量比例、全链路追踪），并且完全不需要改一行 Java 代码。这就是云原生的终极形态。
