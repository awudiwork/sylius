# Nginx 配置文件目录

## 📁 目录结构

```
nginx-configs/
├── sylius-ports.conf         # 端口模式配置（当前使用）✅
├── sylius-shop.conf          # 双域名前台配置（备用）💼
└── sylius-admin.conf         # 双域名后台配置（备用）💼
```

---

## 🎯 配置说明

### 1. 端口模式（当前使用）✅

**文件**: `sylius-ports.conf`

**包含内容**:
- 前台商城 (端口 8090)
- 后台管理 (端口 8091)

**访问方式**:
```
前台: http://your-ip:8090
后台: http://your-ip:8091
```

**特点**:
- ✅ 单个配置文件，便于管理
- ✅ 不需要域名
- ✅ 适合开发/测试环境

**部署命令**:
```bash
../deploy-nginx-port.sh
```

---

### 2. 双域名模式（备用）💼

**文件**:
- `sylius-shop.conf` - 前台域名配置
- `sylius-admin.conf` - 后台域名配置

**访问方式**:
```
前台: http://shop.yourdomain.com
后台: http://admin.yourdomain.com
```

**特点**:
- ✅ 支持 HTTPS（配置 SSL 证书后）
- ✅ URL 美观专业
- ✅ 适合生产环境

**部署命令**:
```bash
../deploy-nginx.sh shop.yourdomain.com admin.yourdomain.com
```

---

## 🔄 配置切换

### 从端口模式切换到双域名模式

```bash
# 1. 停用端口模式
sudo rm /etc/nginx/sites-enabled/sylius-ports.conf

# 2. 启用双域名模式
cd /var/www/sylius
./deploy-nginx.sh shop.yourdomain.com admin.yourdomain.com

# 3. 配置 SSL（可选）
sudo certbot --nginx -d shop.yourdomain.com -d admin.yourdomain.com
```

### 从双域名模式切换到端口模式

```bash
# 1. 停用双域名模式
sudo rm /etc/nginx/sites-enabled/sylius-shop.conf
sudo rm /etc/nginx/sites-enabled/sylius-admin.conf

# 2. 启用端口模式
cd /var/www/sylius
./deploy-nginx-port.sh
```

---

## 📊 配置对比

| 特性 | 端口模式 | 双域名模式 |
|------|----------|-----------|
| **配置文件数量** | 1 个 | 2 个 |
| **访问地址** | IP:端口 | 域名 |
| **前台** | :8090 | shop.domain.com |
| **后台** | :8091 | admin.domain.com |
| **需要域名** | ❌ | ✅ |
| **支持 HTTPS** | ❌ | ✅ |
| **配置复杂度** | 简单 | 中等 |
| **适合环境** | 开发/测试 | 生产 |

---

## 🔧 配置文件详解

### sylius-ports.conf（端口模式）

```nginx
# 前台 server 块
server {
    listen 8090;
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}

# 后台 server 块
server {
    listen 8091;
    location / {
        if ($request_uri = /) {
            return 302 /admin/;
        }
        proxy_pass http://127.0.0.1:8080;
    }
}
```

**关键配置**:
- 前台禁止访问 `/admin` 路径（返回 404）
- 后台根路径自动跳转到 `/admin/`
- 所有请求反向代理到容器 `127.0.0.1:8080`

### sylius-shop.conf（双域名前台）

```nginx
server {
    listen 80;
    server_name shop.example.com;

    location ^~ /admin {
        return 404;  # 前台禁止访问后台
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### sylius-admin.conf（双域名后台）

```nginx
server {
    listen 80;
    server_name admin.example.com;

    location / {
        if ($request_uri = /) {
            return 302 /admin/;
        }
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## 🛡️ 安全建议

### 后台 IP 白名单（推荐）

编辑后台配置，取消注释以下部分：

**端口模式** (`sylius-ports.conf`):
```nginx
server {
    listen 8091;

    # 取消注释这些行
    allow 192.168.1.0/24;    # 允许局域网
    allow 1.2.3.4;           # 允许特定 IP
    deny all;                # 拒绝其他所有 IP
}
```

**双域名模式** (`sylius-admin.conf`):
```nginx
server {
    listen 80;
    server_name admin.example.com;

    # 取消注释这些行
    allow 1.2.3.4;
    deny all;
}
```

### 后台基本认证（推荐）

```bash
# 创建密码文件
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/nginx/.htpasswd admin

# 编辑配置，取消注释
# auth_basic "Admin Area";
# auth_basic_user_file /etc/nginx/.htpasswd;

# 重载 Nginx
sudo nginx -t
sudo systemctl reload nginx
```

---

## 📝 使用建议

### 开发阶段

```bash
✅ 使用端口模式
   - 文件: sylius-ports.conf
   - 访问: IP:8090 / IP:8091
   - 部署: ./deploy-nginx-port.sh
```

### 生产阶段

```bash
✅ 使用双域名模式
   - 文件: sylius-shop.conf + sylius-admin.conf
   - 访问: shop.domain.com / admin.domain.com
   - 部署: ./deploy-nginx.sh shop.domain.com admin.domain.com
   - SSL: sudo certbot --nginx -d shop.domain.com -d admin.domain.com
```

---

## 🆘 常见问题

**Q: 可以同时启用两种模式吗？**

A: 技术上可以，但不推荐。会造成配置混乱。

**Q: 如何修改端口号？**

A: 编辑 `sylius-ports.conf`，修改 `listen 8090` 和 `listen 8091` 为你想要的端口。

**Q: 为什么前台访问不了 /admin？**

A: 这是安全设计，前台端口/域名禁止访问后台路径。请使用后台端口/域名访问。

---

---

## ⚡ 性能优化说明

### 已应用的优化（三个配置文件均包含）

| 优化项 | 配置 | 效果 |
|--------|------|------|
| **HTTP/1.1 持久连接** | `proxy_http_version 1.1`<br/>`proxy_set_header Connection ""` | 减少 TCP 握手次数 |
| **Gzip 压缩** | `gzip_comp_level 6`<br/>`gzip_types text/css ...` | 节省 60-70% 带宽 |
| **代理缓冲优化** | `proxy_buffers 24 4k` | 减少磁盘 I/O |
| **静态资源长期缓存** | `expires 365d`<br/>`Cache-Control "public, immutable"` | 浏览器缓存 1 年 |
| **Host 头优化** | `proxy_set_header Host localhost` | 匹配容器内 Nginx 配置 |
| **客户端缓冲** | `client_body_buffer_size 128k` | 提升上传性能 |

### 后台专用优化（admin 配置）

后台配置针对管理操作进行了特殊优化：

```nginx
# 更大的缓冲区（处理复杂表单）
proxy_buffer_size 8k;
proxy_buffers 32 4k;          # ← 后台 32 个，前台 24 个
proxy_busy_buffers_size 16k;

# 更长的超时时间（导入/导出等耗时操作）
proxy_send_timeout 120;       # ← 后台 120s，前台 60s
proxy_read_timeout 120;       # ← 后台 120s，前台 60s
```

---

## 📐 架构说明

### 端口模式架构

```
外网用户 → 宿主机 Nginx → Docker 容器 → Nginx → PHP-FPM
          (8090/8091)      (8080)         (80)     (9000)
```

### 双域名模式架构

```
外网用户 (shop.domain.com) ┐
                            ├→ 宿主机 Nginx → Docker 容器
外网用户 (admin.domain.com) ┘   (80/443)      (8080)
```

**关键设计原则**：
1. 宿主机 Nginx 只做反向代理、SSL、性能优化
2. 容器内 Nginx 处理 Symfony 路由和 PHP-FPM
3. `Host: localhost` 保证容器内路由正确
4. `X-Forwarded-Host` 传递真实域名给 Symfony

---

## 📋 配置文件最近更新

### 2025-10-15 更新内容

**sylius-admin.conf**:
- ✅ 增加 HTTP/1.1 持久连接优化
- ✅ 增加 Gzip 压缩配置
- ✅ 增加代理缓冲优化
- ✅ 修正 Host 头设置为 `localhost`
- ✅ 增加媒体文件独立 location 块
- ✅ 后台超时时间延长至 120 秒
- ✅ 后台缓冲区增大至 32 个

**sylius-shop.conf**:
- ✅ 已包含完整性能优化（无需修改）

**sylius-ports.conf**:
- ✅ 已包含完整性能优化（无需修改）

---

**最后更新**: 2025-10-15
**维护者**: Sylius 项目部署团队
