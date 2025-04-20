# ![Hysteria 2](logo.svg)

# 支持对接Xboard/V2board面板的Hysteria2后端

### 项目说明

本项目基于hysteria官方内核二次开发，添加了从 Xboard/V2board 获取节点信息、用户鉴权信息与上报用户流量的功能。
性能方面已经由hysteria2内核作者亲自指导优化过了。

### 使用说明

准备工作：安装docker，docker compose

```
curl -fsSL https://get.docker.com | bash -s docker
sudo systemctl start docker
sudo systemctl enable docker
docker --version
docker compose version
```

下载并修改配置文件docker-compose.yml,server.yaml,包括前端信息和后端域名

```
git clone https://github.com/linqh-worker/v2board-hysteria.git hysteria && cd hysteria
```

---生成自签证书

```
vi gen-cert-auto.sh #第三行位置 DOMAIN换成你的节点域名保存后退出

sh gen-cert-auto.sh #运行显示生成证书成功后进行下一步
```

---配置文件server.yaml参考

```
v2board:
  apiHost: https://example.com #v2board面板域名
  apiKey: 123456789 #通讯密钥
  nodeID: 1 #节点id
tls:
  type: tls
  cert: /etc/hysteria/example.com.crt
  key: /etc/hysteria/example.com.key
auth:
  type: v2board
trafficStats:
  listen: 127.0.0.1:7653
acl: 
  inline: 
	- reject(10.0.0.0/8)
    - reject(172.16.0.0/12)
    - reject(192.168.0.0/16)
    - reject(127.0.0.0/8)
    - reject(fc00::/7)
```

启动docker compose

```
docker compose up -d
```

查看日志：

```
docker logs -f hysteria
```

容器停止，更新，后台启动。

```
docker compose down && docker compose pull && docker compose up -d
```
