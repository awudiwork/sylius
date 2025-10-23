# Sylius Nginx 部署完整指南

## 📋 目录

- [快速开始](#-快速开始)
- [配置模式选择](#-配置模式选择)
- [端口模式部署](#-端口模式部署推荐测试环境)
- [双域名模式部署](#-双域名模式部署推荐生产环境)
- [性能优化说明](#-性能优化说明)
- [安全加固](#-安全加固)
- [故障排查](#-故障排查)
- [快速命令参考](#-快速命令参考)

---

## 🚀 快速开始

### 一键部署脚本

```bash
# Linux 服务器上执行
cd /var/www/sylius

# 端口模式（快速开始，无需域名）
./deploy-nginx-port.sh

# 双域名模式（需要先配置域名）
./deploy-nginx.sh shop.yourdomain.com admin.yourdomain.com
```

---

## 🎯 配置模式选择

### 端口模式 vs 双域名模式

| 特性 | 端口模式 ✅ | 双域名模式 💼 |
|------|------------|-------------|
| **配置文件** | `sylius-ports.conf` | `sylius-shop.conf`<br/>`sylius-admin.conf` |
| **访问方式** | `http://IP:8090`<br/>`http://IP:8091` | `http://shop.domain.com`<br/>`http://admin.domain.com` |
| **需要域名** | ❌ 不需要 | ✅ 需要 |
| **支持 HTTPS** | ❌ | ✅ (Let's Encrypt 免费) |
| **配置复杂度** | 简单 | 中等 |
| **部署时间** | 5 分钟 | 30-60 分钟（含 DNS） |
| **适合环境** | 开发/测试 | 生产 |
| **URL 美观度** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

### 推荐选择

- **开发阶段**: 端口模式（快速、简单）
- **生产阶段**: 双域名模式（专业、安全、支持 HTTPS）

---

## 📁 配置文件结构

```
nginx-configs/
├── sylius-ports.conf         # 端口模式配置（8090/8091）
├── sylius-shop.conf          # 双域名前台配置
├── sylius-admin.conf         # 双域名后台配置
└── README.md                 # 本文档
```

---

## 🔧 端口模式部署（推荐：测试环境）

### 特点

✅ 不需要域名
✅ 5 分钟快速部署
✅ 单个配置文件
✅ 适合开发和测试

### 访问地址

- **前台商城**: `http://your-server-ip:8090`
- **后台管理**: `http://your-server-ip:8091`

### Linux 部署步骤

#### 步骤 1: 准备环境

```bash
# SSH 登录服务器
ssh username@your-server-ip

# 进入项目目录
cd /var/www/sylius

# 确认 Docker 容器运行中
docker compose ps
# 确保 app 容器状态为 Up，端口映射为 127.0.0.1:8080->80/tcp
```

#### 步骤 2: 安装 Nginx（如果未安装）

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx -y

# CentOS/RHEL
sudo yum install nginx -y

# 启动并设置开机自启
sudo systemctl start nginx
sudo systemctl enable nginx

# 验证安装
nginx -v
sudo systemctl status nginx
```

#### 步骤 3: 备份现有配置

```bash
# 备份当前配置（重要！）
sudo cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup-$(date +%Y%m%d)

# 停用默认站点（避免冲突）
sudo rm -f /etc/nginx/sites-enabled/default
```

#### 步骤 4: 部署配置文件

```bash
# 复制配置文件到 Nginx 目录
sudo cp /var/www/sylius/nginx-configs/sylius-ports.conf /etc/nginx/sites-available/

# 创建符号链接启用配置
sudo ln -s /etc/nginx/sites-available/sylius-ports.conf /etc/nginx/sites-enabled/

# 验证配置文件
ls -la /etc/nginx/sites-enabled/
```

#### 步骤 5: 测试并应用配置

```bash
# 测试 Nginx 配置语法
sudo nginx -t

# 应该看到:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# 重载 Nginx（不中断服务）
sudo systemctl reload nginx

# 检查 Nginx 状态
sudo systemctl status nginx
```

#### 步骤 6: 配置防火墙

```bash
# Ubuntu/Debian (使用 UFW)
sudo ufw allow 8090/tcp
sudo ufw allow 8091/tcp
sudo ufw status

# CentOS/RHEL (使用 firewalld)
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --permanent --add-port=8091/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

#### 步骤 7: 验证部署

```bash
# 测试前台（商城）
curl -I http://127.0.0.1:8090
# 应该返回: HTTP/1.1 200 OK 或 302

# 测试后台（管理）
curl -I http://127.0.0.1:8091
# 应该返回: HTTP/1.1 302 Found (跳转到 /admin/)

# 检查监听端口
sudo netstat -tuln | grep -E '8090|8091'
# 应该看到:
# tcp  0  0  0.0.0.0:8090  0.0.0.0:*  LISTEN
# tcp  0  0  0.0.0.0:8091  0.0.0.0:*  LISTEN
```

#### 步骤 8: 浏览器测试

在浏览器中访问：
- **前台**: `http://your-server-ip:8090`
- **后台**: `http://your-server-ip:8091` (自动跳转到 `/admin/`)

### 一键部署脚本（端口模式）

```bash
#!/bin/bash
# 保存为 deploy-nginx-port.sh

set -e

echo "🚀 开始部署 Sylius Nginx（端口模式）..."

# 1. 备份现有配置
echo "💾 备份现有配置..."
sudo cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup-$(date +%Y%m%d) 2>/dev/null || true

# 2. 停用其他 Sylius 配置
echo "🛑 停用其他配置..."
sudo rm -f /etc/nginx/sites-enabled/sylius-shop.conf
sudo rm -f /etc/nginx/sites-enabled/sylius-admin.conf
sudo rm -f /etc/nginx/sites-enabled/default

# 3. 复制配置文件
echo "📋 复制配置文件..."
sudo cp /var/www/sylius/nginx-configs/sylius-ports.conf /etc/nginx/sites-available/

# 4. 创建符号链接
echo "🔗 创建符号链接..."
sudo ln -sf /etc/nginx/sites-available/sylius-ports.conf /etc/nginx/sites-enabled/

# 5. 测试配置
echo "🔍 测试 Nginx 配置..."
sudo nginx -t

# 6. 重载 Nginx
echo "🔄 重载 Nginx..."
sudo systemctl reload nginx

# 7. 验证部署
echo ""
echo "✅ 部署完成！"
echo ""
echo "📝 访问地址:"
echo "   前台: http://$(hostname -I | awk '{print $1}'):8090"
echo "   后台: http://$(hostname -I | awk '{print $1}'):8091"
echo ""
echo "🔍 验证命令:"
echo "   curl -I http://127.0.0.1:8090"
echo "   curl -I http://127.0.0.1:8091"
echo ""
```

**使用方法**：

```bash
cd /var/www/sylius
chmod +x deploy-nginx-port.sh
./deploy-nginx-port.sh
```

---

## 🌐 双域名模式部署（推荐：生产环境）

### 特点

✅ URL 美观专业
✅ 支持 HTTPS（免费 Let's Encrypt）
✅ 前后台域名分离
✅ 适合生产环境

### 访问地址

- **前台商城**: `https://shop.yourdomain.com`
- **后台管理**: `https://admin.yourdomain.com`

### Linux 部署步骤

#### 第一步: 配置域名解析

在你的域名服务商（阿里云、腾讯云、Cloudflare）管理面板配置 DNS：

**方式 1: 直接 A 记录解析（推荐）**

```dns
类型    主机记录        记录值              TTL
A       shop           123.456.789.10      600
A       admin          123.456.789.10      600
```

> 将 `123.456.789.10` 替换为你的服务器公网 IP

**方式 2: 使用泛域名解析**

```dns
类型    主机记录        记录值              TTL
A       *              123.456.789.10      600
```

**验证 DNS 解析**（需要等待 5-10 分钟）：

```bash
# 在本地电脑测试
ping shop.yourdomain.com
ping admin.yourdomain.com

# 应该返回你的服务器 IP
```

#### 第二步: 修改配置文件中的域名

**在服务器上直接修改**（推荐）：

```bash
cd /var/www/sylius

# 1. 修改前台域名
sudo nano nginx-configs/sylius-shop.conf
# 找到第 24 行: server_name shop.yourdomain.com;
# 修改为你的实际域名

# 2. 修改后台域名
sudo nano nginx-configs/sylius-admin.conf
# 找到第 29 行: server_name admin.yourdomain.com;
# 修改为你的实际域名
```

**或使用 sed 批量替换**：

```bash
cd /var/www/sylius/nginx-configs

# 替换前台域名
sed -i 's/shop\.yourdomain\.com/shop.example.com/g' sylius-shop.conf

# 替换后台域名
sed -i 's/admin\.yourdomain\.com/admin.example.com/g' sylius-admin.conf

# 验证修改
grep "server_name" sylius-shop.conf sylius-admin.conf
```

#### 第三步: 部署配置文件

```bash
cd /var/www/sylius

# 1. 备份当前配置
echo "💾 备份现有配置..."
sudo cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup-$(date +%Y%m%d)

# 2. 停用端口模式配置
echo "🛑 停用端口模式..."
sudo rm -f /etc/nginx/sites-enabled/sylius-ports.conf
sudo rm -f /etc/nginx/sites-enabled/default

# 3. 复制配置文件到 Nginx 目录
echo "📋 复制配置文件..."
sudo cp nginx-configs/sylius-shop.conf /etc/nginx/sites-available/
sudo cp nginx-configs/sylius-admin.conf /etc/nginx/sites-available/

# 4. 创建符号链接启用配置
echo "🔗 创建符号链接..."
sudo ln -s /etc/nginx/sites-available/sylius-shop.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/sylius-admin.conf /etc/nginx/sites-enabled/

# 5. 验证符号链接
ls -la /etc/nginx/sites-enabled/ | grep sylius
```

#### 第四步: 测试并应用配置

```bash
# 测试 Nginx 配置语法
sudo nginx -t

# 应该看到:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# 重载 Nginx
sudo systemctl reload nginx

# 检查 Nginx 状态
sudo systemctl status nginx
```

#### 第五步: 配置防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

#### 第六步: 验证部署

```bash
# 测试前台
curl -I http://shop.yourdomain.com
# 应该返回: HTTP/1.1 200 OK 或 302

# 测试后台
curl -I http://admin.yourdomain.com
# 应该返回: HTTP/1.1 302 Found (跳转到 /admin/)

# 测试后台实际页面
curl -I http://admin.yourdomain.com/admin/
# 应该返回: HTTP/1.1 200 OK

# 检查监听端口
sudo netstat -tuln | grep :80
# 应该看到: tcp  0  0  0.0.0.0:80  0.0.0.0:*  LISTEN
```

#### 第七步: 配置 HTTPS（强烈推荐）

```bash
# 1. 安装 Certbot
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx -y

# 2. 自动申请并配置 SSL 证书
sudo certbot --nginx -d shop.yourdomain.com -d admin.yourdomain.com

# 按提示操作:
# - 输入邮箱（用于证书到期提醒）
# - 同意服务条款（输入 A）
# - 是否接收通知（Y/N）
# - 选择是否重定向 HTTP 到 HTTPS（推荐选 2 - 重定向）

# 3. 测试自动续期
sudo certbot renew --dry-run

# 4. 查看证书信息
sudo certbot certificates
```

**Certbot 会自动**：
- 申请 Let's Encrypt 免费 SSL 证书（3 个月有效）
- 修改 Nginx 配置文件，添加 HTTPS server 块
- 配置 HTTP 自动跳转到 HTTPS
- 设置自动续期任务

#### 第八步: 浏览器测试

在浏览器中访问：
- **前台**: `https://shop.yourdomain.com`
- **后台**: `https://admin.yourdomain.com`

### 一键部署脚本（双域名模式）

```bash
#!/bin/bash
# 保存为 deploy-nginx.sh
# 使用方法: ./deploy-nginx.sh shop.yourdomain.com admin.yourdomain.com

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <shop-domain> <admin-domain>"
    echo "Example: $0 shop.example.com admin.example.com"
    exit 1
fi

SHOP_DOMAIN=$1
ADMIN_DOMAIN=$2

echo "🚀 开始部署 Sylius Nginx（双域名模式）..."
echo "   前台域名: $SHOP_DOMAIN"
echo "   后台域名: $ADMIN_DOMAIN"
echo ""

cd /var/www/sylius

# 1. 备份现有配置
echo "💾 备份现有配置..."
sudo cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup-$(date +%Y%m%d) 2>/dev/null || true

# 2. 修改配置文件中的域名
echo "📝 修改配置文件域名..."
sed -i "s/shop\.yourdomain\.com/$SHOP_DOMAIN/g" nginx-configs/sylius-shop.conf
sed -i "s/admin\.yourdomain\.com/$ADMIN_DOMAIN/g" nginx-configs/sylius-admin.conf

# 3. 停用其他配置
echo "🛑 停用其他配置..."
sudo rm -f /etc/nginx/sites-enabled/sylius-ports.conf
sudo rm -f /etc/nginx/sites-enabled/default

# 4. 复制配置文件
echo "📋 复制配置文件..."
sudo cp nginx-configs/sylius-shop.conf /etc/nginx/sites-available/
sudo cp nginx-configs/sylius-admin.conf /etc/nginx/sites-available/

# 5. 创建符号链接
echo "🔗 创建符号链接..."
sudo ln -sf /etc/nginx/sites-available/sylius-shop.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/sylius-admin.conf /etc/nginx/sites-enabled/

# 6. 测试配置
echo "🔍 测试 Nginx 配置..."
sudo nginx -t

# 7. 重载 Nginx
echo "🔄 重载 Nginx..."
sudo systemctl reload nginx

# 8. 完成提示
echo ""
echo "✅ 部署完成！"
echo ""
echo "📝 访问地址:"
echo "   前台: http://$SHOP_DOMAIN"
echo "   后台: http://$ADMIN_DOMAIN"
echo ""
echo "🔒 配置 HTTPS (推荐):"
echo "   sudo certbot --nginx -d $SHOP_DOMAIN -d $ADMIN_DOMAIN"
echo ""
echo "🔍 验证命令:"
echo "   curl -I http://$SHOP_DOMAIN"
echo "   curl -I http://$ADMIN_DOMAIN"
echo ""
```

**使用方法**：

```bash
cd /var/www/sylius
chmod +x deploy-nginx.sh
./deploy-nginx.sh shop.yourdomain.com admin.yourdomain.com
```

---

## ⚡ 性能优化说明

### 已应用的优化（所有配置文件均包含）

| 优化项 | 配置 | 效果 |
|--------|------|------|
| **HTTP/1.1 持久连接** | `proxy_http_version 1.1`<br/>`proxy_set_header Connection ""` | 减少 TCP 握手，提升 30% 性能 |
| **Gzip 压缩** | `gzip_comp_level 6`<br/>`gzip_types text/css ...` | 节省 60-70% 带宽 |
| **代理缓冲优化** | `proxy_buffers 24 4k` (前台)<br/>`proxy_buffers 32 4k` (后台) | 减少磁盘 I/O |
| **静态资源长期缓存** | `expires 365d`<br/>`Cache-Control "public, immutable"` | 浏览器缓存 1 年 |
| **Host 头优化** | `proxy_set_header Host localhost` | 匹配容器内 Nginx 配置 |
| **客户端缓冲** | `client_body_buffer_size 128k` | 提升上传性能 |

### 后台专用优化

后台配置针对管理操作进行了特殊优化：

```nginx
# 更大的缓冲区（处理复杂表单）
proxy_buffer_size 8k;
proxy_buffers 32 4k;          # 后台 32 个，前台 24 个
proxy_busy_buffers_size 16k;

# 更长的超时时间（导入/导出等耗时操作）
proxy_send_timeout 120;       # 后台 120s，前台 60s
proxy_read_timeout 120;       # 后台 120s，前台 60s
```

---

## 🛡️ 安全加固

### 1. 后台 IP 白名单（推荐）

**端口模式** (`sylius-ports.conf`):

```bash
sudo nano /etc/nginx/sites-available/sylius-ports.conf
```

取消注释后台 server 块中的以下行：

```nginx
server {
    listen 8091;

    # 取消注释以下行
    allow 192.168.1.0/24;    # 允许局域网
    allow 1.2.3.4;           # 允许特定公网 IP
    deny all;                # 拒绝其他所有 IP
}
```

**双域名模式** (`sylius-admin.conf`):

```bash
sudo nano /etc/nginx/sites-available/sylius-admin.conf
```

```nginx
server {
    server_name admin.yourdomain.com;

    # 取消注释以下行
    allow 1.2.3.4;           # 你的办公室 IP
    allow 5.6.7.0/24;        # 你的 VPN IP 段
    deny all;
}
```

**应用配置**：

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 2. HTTP 基本认证（推荐）

```bash
# 1. 安装工具
sudo apt install apache2-utils -y

# 2. 创���密码文件
sudo htpasswd -c /etc/nginx/.htpasswd admin
# 输入密码两次

# 3. 添加更多用户（不要用 -c 参数）
sudo htpasswd /etc/nginx/.htpasswd user2

# 4. 编辑配置文件
sudo nano /etc/nginx/sites-available/sylius-admin.conf  # 或 sylius-ports.conf

# 取消注释以下行:
# auth_basic "Admin Area - Restricted Access";
# auth_basic_user_file /etc/nginx/.htpasswd;

# 5. 应用配置
sudo nginx -t
sudo systemctl reload nginx
```

### 3. 限制请求速率（防止暴力破解）

在配置文件中添加（已默认包含，可根据需要调整）：

```nginx
# 在 http 块中（/etc/nginx/nginx.conf）
limit_req_zone $binary_remote_addr zone=admin_limit:10m rate=10r/m;

# 在 server 块中
location /admin {
    limit_req zone=admin_limit burst=5;
    # ... 其他配置
}
```

### 4. 隐藏 Nginx 版本号

```bash
# 编辑 Nginx 主配置
sudo nano /etc/nginx/nginx.conf

# 在 http 块中添加:
http {
    server_tokens off;
    # ... 其他配置
}

# 应用配置
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🆘 故障排查

### 问题 1: Nginx 启动失败

**错误信息**: `Job for nginx.service failed`

**排查步骤**:

```bash
# 查看详细错误
sudo systemctl status nginx
sudo journalctl -xeu nginx.service

# 测试配置
sudo nginx -t

# 检查端口占用
sudo netstat -tuln | grep -E ':80|:8090|:8091'

# 检查是否有其他进程占用端口
sudo lsof -i :80
sudo lsof -i :8090
```

**常见原因**:
- 配置文件语法错误
- 端口被占用（Apache、其他 Nginx）
- 权限不足

---

### 问题 2: 502 Bad Gateway

**原因**: Docker 容器未运行或端口映射错误

**排查步骤**:

```bash
# 1. 检查容器状态
docker compose ps
# 确保 app 容器状态为 Up

# 2. 检查端口映射
docker compose ps | grep app
# 确保有: 127.0.0.1:8080->80/tcp

# 3. 测试容器内服务
curl -I http://127.0.0.1:8080
# 应该返回 200 或 302

# 4. 查看容器日志
docker compose logs -f app

# 5. 重启容器
docker compose restart app
```

---

### 问题 3: 403 Forbidden

**原因**: 文件权限不足或 SELinux 阻止

**排查步骤**:

```bash
# 1. 检查文件权限
docker compose exec app ls -la /app/public/

# 2. 修复权限
docker compose exec app chown -R www-data:www-data /app/public/
docker compose exec app chmod -R 755 /app/public/

# 3. 检查 SELinux (CentOS/RHEL)
getenforce
# 如果是 Enforcing，临时禁用测试:
sudo setenforce 0

# 永久禁用 SELinux (不推荐，仅测试用)
sudo nano /etc/selinux/config
# 修改: SELINUX=disabled
```

---

### 问题 4: 域名无法访问

**排查步骤**:

```bash
# 1. 测试 DNS 解析
ping shop.yourdomain.com
nslookup shop.yourdomain.com

# 2. 测试本地访问
curl -I http://127.0.0.1:80

# 3. 检查防火墙
sudo ufw status
sudo firewall-cmd --list-all

# 4. 检查 Nginx 配置
sudo nginx -T | grep server_name

# 5. 查看 Nginx 日志
sudo tail -f /var/log/nginx/error.log
```

---

### 问题 5: SSL 证书申请失败

**常见原因**:
- DNS 未生效
- 防火墙拦截 80/443 端口
- 域名已有其他证书

**排查步骤**:

```bash
# 1. 验证 DNS
ping shop.yourdomain.com

# 2. 测试 HTTP 访问
curl -I http://shop.yourdomain.com

# 3. 查看详细错误
sudo certbot --nginx -d shop.yourdomain.com -d admin.yourdomain.com --dry-run

# 4. 查看 Certbot 日志
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# 5. 手动验证域名所有权
sudo certbot certonly --webroot -w /var/www/sylius/public -d shop.yourdomain.com
```

---

### 问题 6: 静态资源 404

**原因**: 前端资源未编译

**解决步骤**:

```bash
# 1. 检查文件是否存在
docker compose exec app ls -la /app/public/build/

# 2. 编译前端资源
docker compose exec app bash -c 'cd /app && yarn install && yarn encore production'

# 3. 修复权限
docker compose exec app chown -R www-data:www-data /app/public/

# 4. 验证文件
docker compose exec app ls -la /app/public/build/shop/
docker compose exec app ls -la /app/public/build/admin/
```

---

## 📐 架构说明

### 端口模式架构

```
外网用户
  ↓
http://server-ip:8090 (前台) / :8091 (后��)
  ↓
宿主机 Nginx (监听 8090/8091)
  ↓
反向代理到 127.0.0.1:8080
  ↓
Docker 容器 app (端口映射 8080->80)
  ↓
容器内 Nginx (监听 80)
  ↓
容器内 PHP-FPM (监听 9000)
  ↓
Symfony/Sylius 应用
```

### 双域名模式架构

```
外网用户
  ↓
https://shop.domain.com / admin.domain.com
  ↓
宿主机 Nginx (监听 80/443)
  ├─ SSL 终止
  ├─ Gzip 压缩
  └─ 反向代理到 127.0.0.1:8080
  ↓
Docker 容器 app (端口映射 8080->80)
  ↓
容器内 Nginx (监听 80)
  ↓
容器内 PHP-FPM (监听 9000)
  ↓
Symfony/Sylius 应用
```

**关键设计原则**:
1. 宿主机 Nginx: 反向代理、SSL、性能优化
2. 容器内 Nginx: Symfony 路由、PHP-FPM 代理
3. `Host: localhost`: 保证容器内路由正确
4. `X-Forwarded-Host`: 传递真实域名给 Symfony

---

## 🔄 配置切换

### 从端口模式切换到双域名模式

```bash
# 1. 停用端口模式
sudo rm /etc/nginx/sites-enabled/sylius-ports.conf

# 2. 启用双域名模式
cd /var/www/sylius
./deploy-nginx.sh shop.yourdomain.com admin.yourdomain.com

# 3. 配置 HTTPS
sudo certbot --nginx -d shop.yourdomain.com -d admin.yourdomain.com

# 4. 验证
curl -I https://shop.yourdomain.com
```

### 从双域名模式切换到端口模式

```bash
# 1. 停用双域名模式
sudo rm /etc/nginx/sites-enabled/sylius-shop.conf
sudo rm /etc/nginx/sites-enabled/sylius-admin.conf

# 2. 启用端口模式
cd /var/www/sylius
./deploy-nginx-port.sh

# 3. 验证
curl -I http://127.0.0.1:8090
```

---

## 📝 快速命令参考

### Nginx 管理

```bash
# 测试配置
sudo nginx -t

# 重载配置（推荐，不中断服务）
sudo systemctl reload nginx

# 重启服务
sudo systemctl restart nginx

# 查看状态
sudo systemctl status nginx

# 查看完整配置
sudo nginx -T

# 查看已启用的站点
ls -la /etc/nginx/sites-enabled/
```

### 日志查看

```bash
# Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# Nginx 访问日志
sudo tail -f /var/log/nginx/access.log

# 前台访问日志（双域名模式）
sudo tail -f /var/log/nginx/sylius-shop-access.log

# 后台访问日志
sudo tail -f /var/log/nginx/sylius-admin-access.log

# Docker 容器日志
docker compose logs -f app
```

### Docker 管理

```bash
# 查看容器状态
docker compose ps

# 重启容器
docker compose restart app

# 查看容器日志
docker compose logs -f app

# 进入容器
docker compose exec app bash

# 检查端口映射
docker compose ps | grep 8080
```

### SSL 证书管理

```bash
# 申请证书
sudo certbot --nginx -d shop.domain.com -d admin.domain.com

# 查看证书
sudo certbot certificates

# 测试续期
sudo certbot renew --dry-run

# 手动续期
sudo certbot renew

# 撤销证书
sudo certbot revoke --cert-name shop.domain.com
```

### 防火墙管理

```bash
# Ubuntu/Debian (UFW)
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8090/tcp
sudo ufw allow 8091/tcp

# CentOS/RHEL (firewalld)
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --reload
```

---

## 📋 部署检查清单

### 端口模式部署清单

- [ ] Docker 容器运行正常
- [ ] Nginx 已安装并运行
- [ ] 配置文件已复制到 `/etc/nginx/sites-available/`
- [ ] 符号链接已创建到 `/etc/nginx/sites-enabled/`
- [ ] Nginx 配置测试通过 (`nginx -t`)
- [ ] 防火墙已开放 8090/8091 端口
- [ ] 前台可访问 (`http://IP:8090`)
- [ ] 后台可访问 (`http://IP:8091`)
- [ ] 后台自动跳转到 `/admin/`
- [ ] 前台无法访问 `/admin`（返回 404）

### 双域名模式部署清单

- [ ] DNS 解析配置正确
- [ ] 配置文件中的域名已修改
- [ ] Docker 容器运行正常
- [ ] Nginx 已安装并运行
- [ ] 配置文件已部署
- [ ] Nginx 配置测试通过
- [ ] 防火墙已开放 80/443 端口
- [ ] 前台域名可以访问
- [ ] 后台域名可以访问
- [ ] 后台自动跳转到 `/admin/`
- [ ] 前台无法访问 `/admin`
- [ ] SSL 证书配置成功
- [ ] HTTP 自动跳转到 HTTPS
- [ ] 静态资源正常加载
- [ ] 图片上传功能正常

---

## 🎓 最佳实践

### 开发环境

```bash
✅ 使用端口模式
✅ 禁用 HTTPS（避免证书警告）
✅ 启用详细日志
✅ 不启用 IP 白名单
```

### 生产环境

```bash
✅ 使用双域名模式
✅ 启用 HTTPS（Let's Encrypt）
✅ 启用后台 IP 白名单
✅ 启用 HTTP 基本认证
✅ 配置自动备份
✅ 配置监控告警
✅ 定期更新 SSL 证书
```

---

## 📞 技术支持

### 常见问题

- Nginx 配置文件位置: `/etc/nginx/sites-available/`
- Nginx 日志位置: `/var/log/nginx/`
- Docker 项目位置: `/var/www/sylius`
- SSL 证书位置: `/etc/letsencrypt/live/`

### 有用的资源

- Nginx 官方文档: https://nginx.org/en/docs/
- Let's Encrypt 文档: https://letsencrypt.org/docs/
- Sylius 官方文档: https://docs.sylius.com/

---

**最后更新**: 2025-10-23
**文档版本**: 2.0
**维护者**: Sylius 项目部署团队
