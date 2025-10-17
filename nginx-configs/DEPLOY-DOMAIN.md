# Sylius 双域名部署完整指南

## 📋 前置准备

### 1. 准备域名

你需要两个域名（或子域名）：
- `shop.yourdomain.com` - 前台商城
- `admin.yourdomain.com` - 后台管理

> 💡 **提示**：可以是独立域名或子域名，推荐使用子域名方便管理。

---

## 🌐 第一步：配置域名解析

在你的域名服务商（如阿里云、腾讯云、Cloudflare）管理面板配置 DNS：

### 方式 1：直接 A 记录解析

```dns
类型    主机记录        记录值              TTL
A       shop           123.456.789.10      600
A       admin          123.456.789.10      600
```

> 将 `123.456.789.10` 替换为你的服务器公网 IP

### 方式 2：使用泛域名解析

```dns
类型    主机记录        记录值              TTL
A       *              123.456.789.10      600
```

> 这样所有子域名都会指向你的服务器

### 验证 DNS 解析

```bash
# 在本地电脑测试（需要等待 DNS 生效，通常 5-10 分钟）
ping shop.yourdomain.com
ping admin.yourdomain.com

# 应该返回你的服务器 IP
```

---

## 📁 第二步：修改配置文件中的域名

### 1. 修改前台域名

```bash
# 在本地修改
cd E:\Code\Sylius\nginx-configs
notepad sylius-shop.conf
```

**修改第 24 行**：
```nginx
server_name shop.yourdomain.com;  # 改为你的实际域名
```

### 2. 修改后台域名

```bash
notepad sylius-admin.conf
```

**修改第 29 行**：
```nginx
server_name admin.yourdomain.com;  # 改为你的实际域名
```

### 3. 保存并上传到服务器

```bash
# 方式 1: 使用 Git（推荐）
git add nginx-configs/sylius-*.conf
git commit -m "配置双域名"
git push

# 然后在服务器上拉取
ssh user@your-server-ip
cd /var/www/sylius
git pull

# 方式 2: 使用 SCP 直接上传
scp nginx-configs/sylius-admin.conf user@your-server-ip:/var/www/sylius/nginx-configs/
scp nginx-configs/sylius-shop.conf user@your-server-ip:/var/www/sylius/nginx-configs/
```

---

## ⚙️ 第三步：服务器端部署配置

### SSH 登录服务器

```bash
ssh user@your-server-ip
cd /var/www/sylius
```

### 1. 备份当前配置（重要！）

```bash
# 备份 Nginx 配置
sudo cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup-$(date +%Y%m%d)

# 查看当前配置
ls -la /etc/nginx/sites-enabled/
```

### 2. 停用端口模式配置

```bash
# 移除当前端口模式的配置（如果存在）
sudo rm -f /etc/nginx/sites-enabled/sylius-ports.conf

# 验证是否删除
ls -la /etc/nginx/sites-enabled/
```

### 3. 复制配置文件到 Nginx 目录

```bash
# 复制配置文件到 sites-available
sudo cp /var/www/sylius/nginx-configs/sylius-shop.conf /etc/nginx/sites-available/
sudo cp /var/www/sylius/nginx-configs/sylius-admin.conf /etc/nginx/sites-available/

# 验证复制成功
ls -la /etc/nginx/sites-available/ | grep sylius
```

### 4. 创建符号链接启用配置

```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/sylius-shop.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/sylius-admin.conf /etc/nginx/sites-enabled/

# 验证符号链接
ls -la /etc/nginx/sites-enabled/ | grep sylius
```

应该看到类似输出：
```
lrwxrwxrwx 1 root root   48 Oct 15 12:00 sylius-admin.conf -> /etc/nginx/sites-available/sylius-admin.conf
lrwxrwxrwx 1 root root   47 Oct 15 12:00 sylius-shop.conf -> /etc/nginx/sites-available/sylius-shop.conf
```

### 5. 测试 Nginx 配置

```bash
# 测试配置语法
sudo nginx -t
```

**期望输出**：
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

如果报错，检查：
- 域名是否正确配置
- 配置文件是否有语法错误
- 端口 80 是否被占用

### 6. 重载 Nginx

```bash
# 方式 1: 重载配置（推荐，不中断服务）
sudo systemctl reload nginx

# 方式 2: 重启服务（如果重载失败）
sudo systemctl restart nginx

# 检查 Nginx 状态
sudo systemctl status nginx
```

---

## ✅ 第四步：验证部署

### 1. 检查 Nginx 监听端口

```bash
sudo netstat -tuln | grep :80
```

应该看到：
```
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN
```

### 2. 检查 Docker 容器运行状态

```bash
cd /var/www/sylius
docker compose ps
```

确保 `app` 容器的端口映射是 `127.0.0.1:8080->80/tcp`

### 3. 测试域名访问

```bash
# 测试前台
curl -I http://shop.yourdomain.com
# 应该返回 HTTP/1.1 200 OK 或 302

# 测试后台
curl -I http://admin.yourdomain.com
# 应该返回 HTTP/1.1 302 Found (跳转到 /admin/)

# 测试后台实际页面
curl -I http://admin.yourdomain.com/admin/
# 应该返回 HTTP/1.1 200 OK
```

### 4. 浏览器测试

在浏览器中访问：
- **前台**: http://shop.yourdomain.com
- **后台**: http://admin.yourdomain.com（会自动跳转到 /admin/）

---

## 🔒 第五步：配置 HTTPS（强烈推荐）

### 安装 Certbot

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx -y
```

### 自动配置 SSL 证书

```bash
# 为两个域名同时申请证书
sudo certbot --nginx -d shop.yourdomain.com -d admin.yourdomain.com

# 按提示操作：
# 1. 输入邮箱
# 2. 同意服务条款（A）
# 3. 选择是否接收通知（Y/N）
# 4. 选择是否重定向 HTTP 到 HTTPS（推荐选 2）
```

**Certbot 会自动**：
- 申请 Let's Encrypt 免费证书
- 修改 Nginx 配置文件
- 添加 HTTPS server 块
- 配置 HTTP 自动跳转到 HTTPS

### 验证 SSL 配置

```bash
# 测试证书
sudo certbot certificates

# 测试自动续期
sudo certbot renew --dry-run
```

### 浏览器测试 HTTPS

- **前台**: https://shop.yourdomain.com
- **后台**: https://admin.yourdomain.com

---

## 🛡️ 第六步：安全加固（可选）

### 1. 后台 IP 白名单

编辑后台配置：
```bash
sudo nano /etc/nginx/sites-available/sylius-admin.conf
```

取消注释以下行（第 56-58 行）：
```nginx
allow 1.2.3.4;            # 你的办公室 IP
allow 5.6.7.0/24;         # 你的 VPN IP 段
deny all;                 # 拒绝其他所有 IP
```

### 2. HTTP 基本认证

```bash
# 安装工具
sudo apt install apache2-utils -y

# 创建密码文件
sudo htpasswd -c /etc/nginx/.htpasswd admin

# 输入密码两次
```

编辑后台配置：
```bash
sudo nano /etc/nginx/sites-available/sylius-admin.conf
```

取消注释以下行（第 61-62 行）：
```nginx
auth_basic "Admin Area - Restricted Access";
auth_basic_user_file /etc/nginx/.htpasswd;
```

重载 Nginx：
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔄 回滚到端口模式

如果需要回滚：

```bash
# 1. 停用双域名配置
sudo rm /etc/nginx/sites-enabled/sylius-shop.conf
sudo rm /etc/nginx/sites-enabled/sylius-admin.conf

# 2. 启用端口模式配置
sudo cp /var/www/sylius/nginx-configs/sylius-ports.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/sylius-ports.conf /etc/nginx/sites-enabled/

# 3. 测试并重载
sudo nginx -t
sudo systemctl reload nginx
```

---

## 📊 最终架构

```
外网访问
  │
  ├─ https://shop.yourdomain.com (443)
  │   ↓
  │   宿主机 Nginx (/etc/nginx/sites-enabled/sylius-shop.conf)
  │   ↓
  │   反向代理到 127.0.0.1:8080
  │   ↓
  │   Docker 容器内 Nginx (80)
  │   ↓
  │   PHP-FPM (9000)
  │   ↓
  │   Symfony 应用
  │
  └─ https://admin.yourdomain.com (443)
      ↓
      宿主机 Nginx (/etc/nginx/sites-enabled/sylius-admin.conf)
      ↓
      反向代理到 127.0.0.1:8080
      ↓
      Docker 容器内 Nginx (80)
      ↓
      PHP-FPM (9000)
      ↓
      Symfony 应用
```

---

## 🆘 常见问题排查

### 问题 1：访问域名显示 Nginx 默认页面

**原因**: 配置文件未正确加载

**解决**:
```bash
# 检查配置是否启用
ls -la /etc/nginx/sites-enabled/

# 检查配置中的 server_name
sudo nginx -T | grep server_name

# 重新加载配置
sudo systemctl reload nginx
```

---

### 问题 2：502 Bad Gateway

**原因**: Docker 容器未运行或端口映射错误

**解决**:
```bash
# 检查容器状态
docker compose ps

# 检查端口映射
docker compose ps | grep 8080

# 重启容器
docker compose restart app

# 查看容器日志
docker compose logs -f app
```

---

### 问题 3：域名无法访问

**原因**: DNS 未生效或防火墙拦截

**解决**:
```bash
# 测试 DNS 解析
ping shop.yourdomain.com

# 检查防火墙
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# CentOS/RHEL
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

---

### 问题 4：静态资源 404

**原因**: 前端资源未编译

**解决**:
```bash
docker compose exec app bash
yarn encore production
exit
```

---

## 📝 部署检查清单

部署完成后，请逐项检查：

- [ ] DNS 解析配置正确
- [ ] 配置文件中的域名已修改
- [ ] Nginx 配置测试通过 (`nginx -t`)
- [ ] Nginx 服务运行正常
- [ ] Docker 容器运行正常
- [ ] 前台域名可以访问
- [ ] 后台域名可以访问
- [ ] 后台自动跳转到 /admin/
- [ ] 前台无法访问 /admin（返回 404）
- [ ] SSL 证书配置成功（如果使用 HTTPS）
- [ ] 静态资源正常加载
- [ ] 图片上传功能正常

---

## 📞 快速命令参考

```bash
# 查看 Nginx 配置
sudo nginx -T

# 查看已启用的站点
ls -la /etc/nginx/sites-enabled/

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 查看前台访问日志
sudo tail -f /var/log/nginx/sylius-shop-access.log

# 查看后台访问日志
sudo tail -f /var/log/nginx/sylius-admin-access.log

# 测试 Nginx 配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx

# 重启 Nginx
sudo systemctl restart nginx

# 查看 Nginx 状态
sudo systemctl status nginx

# 查看 Docker 容器状态
docker compose ps

# 查看容器日志
docker compose logs -f app

# 重启 Docker 容器
docker compose restart app
```

---

**部署完成时间**: 约 30-60 分钟（包含 DNS 生效时间）
**最后更新**: 2025-10-15
**文档版本**: 1.0
