# Sylius 部署文档

## 📋 目录

- [系统要求](#系统要求)
- [项目架构说明](#项目架构说明)
- [开发环境部署](#开发环境部署)
- [生产环境部署](#生产环境部署)
- [生产环境代码更新](#生产环境代码更新)
- [Docker 镜像管理](#docker-镜像管理)
- [常用管理命令](#常用管理命令)
- [故障排查](#故障排查)

---

## 系统要求

### 基础环境

- **操作系统**: Linux / macOS / Windows (仅支持 WSL)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Git**: 任意版本
- **Make**: GNU Make (用于执行 Makefile 命令)

### PHP 要求

- **PHP 版本**: 8.2 或更高
- **必需扩展**:
  - `gd` (图片处理,支持 WebP/JPEG/PNG)
  - `exif` (图片元数据)
  - `fileinfo` (文件类型检测)
  - `intl` (国际化)
  - `sodium` (加密)
  - `pdo_mysql` (MySQL 数据库)
  - `mbstring` (多字节字符串)
  - `zip` (压缩文件)
  - `bcmath` (高精度数学)

### 数据库支持

支持以下任一数据库:

- **MySQL**: 8.0+
- **MariaDB**: 10.4.10+
- **PostgreSQL**: 13.9+

默认配置使用 MySQL 5.7 (docker-compose.yml)

### Node.js 要求

- **Node.js**: 20.x
- **包管理器**: Yarn (推荐) 或 npm

---

## 项目架构说明

### 核心配置文件

```
Sylius/
├── .docker/
│   └── dev/
│       ├── Dockerfile          # 开发/生产环境镜像
│       └── php.ini             # PHP 配置
├── docker-compose.yml          # Docker 服务编排
├── Makefile                    # 自动化部署脚本
├── .env                        # 默认环境变量 (dev)
├── .env.local                  # 本地环境变量 (prod)
└── public/
    └── media/                  # 上传文件目录 (需要权限)
```

### Docker 服务架构

| 服务名 | 镜像 | 端口 | 说明 |
|--------|------|------|------|
| `app` | php:8.2-fpm + nginx | 80 | PHP-FPM + Nginx Web 服务器 |
| `mysql` | mysql:5.7 | 3306 | MySQL 数据库 |
| `mailhog` | mailhog/mailhog | 8025 | 邮件测试工具 (开发用) |
| `blackfire` | blackfire/blackfire:2 | 8307 | 性能分析工具 (可选) |

---

## 开发环境部署

### 1. 克隆项目

```bash
# 创建项目目录
sudo mkdir -p /var/www/sylius
sudo chown -R $USER:$USER /var/www/sylius

# 克隆代码
cd /var/www
git clone https://github.com/Sylius/Sylius.git sylius
cd sylius
```

### 2. 配置环境变量

#### ⚠️ 关键步骤：确保使用开发环境配置

开发环境使用 `.env` 文件（默认已配置为 dev 模式）：

```bash
# 查看默认配置
cat .env | grep APP_ENV
# 输出: APP_ENV=dev
```

**必须检查和修改的配置：**

**A. 检查是否存在 `.env.local` 文件**

```bash
# 检查文件是否存在
ls -la .env.local
```

- **如果存在且内容是 `APP_ENV=prod`**：
  ```bash
  # 方式1: 删除该文件 (推荐开发环境)
  rm .env.local
  
  # 方式2: 重命名备份
  mv .env.local .env.local.prod.backup
  ```

- **原因**：`.env.local` 会覆盖 `.env` 的配置，如果设置了 `prod`，会导致开发环境错误

**B. 修改 `docker-compose.yml` 中的环境变量**

```bash
nano docker-compose.yml
```

找到 `app` 服务的 `environment` 部分，**修改为**：

```yaml
services:
    app:
        environment:
            APP_ENV: "dev"  # ← 改为 dev (重要!)
            DATABASE_URL: "mysql://root:mysql@mysql/sylius_dev?charset=utf8mb4"
```

**开发环境关键配置总结：**

| 配置文件 | 配置项 | 开发环境值 |
|---------|--------|-----------|
| `.env` | `APP_ENV` | `dev` ✅ |
| `.env` | `APP_DEBUG` | `1` ✅ |
| `.env.local` | - | **删除或不存在** ✅ |
| `docker-compose.yml` | `APP_ENV` | `"dev"` ✅ |
| `docker-compose.yml` | `DATABASE_URL` | `sylius_dev` ✅ |

### 3. 启动开发环境

```bash
# 方式1: 先启动容器再初始化 (推荐 - 首次部署)
docker compose up -d           # 启动容器
sleep 15                       # 等待 MySQL 完全启动 (首次部署必须!)
docker compose exec app make init  # 在容器内执行初始化

# 方式2: 完全手动分步执行 (调试时使用)
docker compose up -d           # 启动容器
sleep 15                       # 等待 MySQL 完全启动
docker compose exec app make install   # 步骤1: 安装 Composer 依赖
docker compose exec app make backend    # 步骤2: 创建数据库并加载数据
docker compose exec app make frontend   # 步骤3: 编译前端资源
```

> **⚠️ 重要提示**：
> - `make init` = `make install` + `make backend` + `make frontend`
> - 首次部署时，MySQL 容器需要 10-20 秒初始化
> - 如果报错 "无法连接数据库"，等待 15 秒后重新执行 `docker compose exec app make init`

### 4. 访问开发环境

```bash
# 浏览器访问
open http://localhost

# 或使用 curl 测试
curl http://localhost
```

**默认访问地址**:
- 前台: http://localhost
- 后台: http://localhost/admin
- 邮件测试: http://localhost:8025

### 5. 创建管理员账号

```bash
docker compose exec app bin/console sylius:admin-user:create

# 按提示输入:
# - 邮箱
# - 用户名
# - 密码
```

### 6. 开发模式前端编译

```bash
# 监听文件变化并自动编译 (推荐)
docker compose exec app yarn watch

# 或手动编译
docker compose exec app yarn build
```

---

## 生产环境部署

### 1. 准备生产服务器

```bash
# 创建项目目录
sudo mkdir -p /var/www/sylius
sudo chown -R $USER:$USER /var/www/sylius

# 上传项目代码
# 方式1: Git 克隆
cd /var/www
git clone https://github.com/Sylius/Sylius.git sylius

# 方式2: 直接上传代码包
scp -r ./sylius user@server:/var/www/
```

### 2. 准备必需配置文件

#### ⚠️ 生产环境部署必须上传和配置的核心文件

在部署生产环境前，需要确保以下文件已正确配置并上传到服务器：

**核心文件清单**:

| 文件 | 路径 | 作用 | 是否必需 |
|------|------|------|----------|
| `Makefile` | 项目根目录 | 自动化部署脚本 | ✅ 强烈推荐 |
| `framework.yaml` | `config/packages/` | Symfony 核心配置（包括 trusted proxies） | ✅ 必需 |
| `Dockerfile` | `.docker/dev/` | Docker 镜像构建配置 | ✅ 必需 |
| `docker-compose.yml` | 项目根目录 | Docker 服务编排 | ✅ 必需 |
| `.env.local` | 项目根目录 | 生产环境变量（覆盖 `.env`） | ✅ 必需 |

**1. 确认 Makefile 存在**

```bash
cd /var/www/sylius
ls -la Makefile

# 如果不存在，需要从开发环境复制或创建
```

**2. 检查 framework.yaml 配置**

确保 `config/packages/framework.yaml` 包含以下配置（反向代理环境必需）：

```yaml
framework:
    # 信任反向代理的 HTTP 头
    trusted_proxies: '127.0.0.1,REMOTE_ADDR'
    trusted_headers:
        - 'x-forwarded-for'
        - 'x-forwarded-host'
        - 'x-forwarded-proto'
        - 'x-forwarded-port'
```

**3. 确认 Dockerfile 和 docker-compose.yml 已上传**

```bash
ls -la .docker/dev/Dockerfile
ls -la docker-compose.yml
```

> **💡 提示**：
> - 如果缺少这些文件，生产环境将无法正常启动或运行
> - `framework.yaml` 的 trusted proxies 配置对于反向代理环境至关重要，否则会导致 URL 重定向错误
> - 所有配置文件建议通过 Git 版本控制管理

### 3. 配置生产环境变量

#### ⚠️ 关键步骤：确保使用生产环境配置

**A. 创建 `.env.local` 文件（生产环境必须）**

```bash
cd /var/www/sylius
nano .env.local
```

**生产环境完整配置示例**:

```env
###> symfony/framework-bundle ###
APP_ENV=prod
APP_DEBUG=0
APP_SECRET=your-random-secret-key-here-change-me
###< symfony/framework-bundle ###

###> doctrine/doctrine-bundle ###
# 注意: 生产环境数据库连接由 docker-compose.yml 定义
# DATABASE_URL=mysql://root:mysql@mysql/sylius_prod?charset=utf8mb4
###< doctrine/doctrine-bundle ###

###> lexik/jwt-authentication-bundle ###
JWT_SECRET_KEY=%kernel.project_dir%/config/jwt/private.pem
JWT_PUBLIC_KEY=%kernel.project_dir%/config/jwt/public.pem
JWT_PASSPHRASE=your-jwt-passphrase-here
###< lexik/jwt-authentication-bundle ###

###> symfony/mailer ###
# 配置真实邮件服务 (SMTP)
MAILER_DSN=smtp://username:password@smtp.example.com:587
###< symfony/mailer ###

SYLIUS_PAYMENT_ENCRYPTION_KEY_PATH=%kernel.project_dir%/config/encryption/prod.key
```

**生产环境必须修改的配置：**
- `APP_SECRET`: 生成随机字符串 (至少 32 位)
- `JWT_PASSPHRASE`: JWT 加密密码
- `MAILER_DSN`: 真实邮件服务配置

**生成随机密钥：**
```bash
# 生成 APP_SECRET
openssl rand -hex 32

# 生成 JWT_PASSPHRASE
openssl rand -hex 32
```

**生产环境关键配置总结：**

| 配置文件 | 配置项 | 生产环境值 |
|---------|--------|-----------|
| `.env` | `APP_ENV` | `dev` (不修改) |
| `.env.local` | `APP_ENV` | `prod` ✅ (必须创建) |
| `.env.local` | `APP_DEBUG` | `0` ✅ |
| `.env.local` | `APP_SECRET` | 随机字符串 ✅ |
| `docker-compose.yml` | `APP_ENV` | `"prod"` ✅ |
| `docker-compose.yml` | `DATABASE_URL` | `sylius_prod` ✅ |

> **💡 提示**：`.env.local` 的配置优先级高于 `.env`，因此生产环境只需创建 `.env.local` 覆盖即可。

### 3. 修改 docker-compose.yml (生产环境)

编辑 `docker-compose.yml`,确保 `APP_ENV` 设置为 `prod`:

```yaml
services:
    app:
        environment:
            APP_ENV: "prod"  # 确保这里是 prod
            DATABASE_URL: "mysql://root:mysql@mysql/sylius_prod?charset=utf8mb4"
```

### 4. 部署生产环境

```bash
# 停止旧容器 (如果存在)
docker compose down

# 构建并启动容器
docker compose build --no-cache
docker compose up -d

# ⚠️ 等待 MySQL 完全启动 (首次部署建议 15-20 秒)
sleep 15

# 检查 MySQL 是否就绪
docker compose exec mysql mysqladmin ping -h localhost -proot

# 初始化项目 (生产模式)
docker compose exec app make init
```

> **⚠️ 首次部署注意事项**：
> - 如果 `make init` 失败并提示数据库连接错误，说明 MySQL 还未完全启动
> - 解决方法：等待 10-15 秒后重新执行 `docker compose exec app make init`
> - 建议使用 `docker compose logs mysql` 查看 MySQL 启动日志，确认启动完成

### 5. 生产环境优化

```bash
# 编译优化后的前端资源
docker compose exec app yarn encore production

# 清理和预热缓存
docker compose exec app bin/console cache:clear --env=prod
docker compose exec app bin/console cache:warmup --env=prod

# 修复文件权限
docker compose exec app chown -R www-data:www-data var/ public/media/
docker compose exec app chmod -R 775 var/ public/media/
```

### 6. 创建生产环境管理员

```bash
docker compose exec app bin/console sylius:admin-user:create
```

### 7. 生产环境端口配置

如需修改默认端口,创建 `compose.override.yml`:

```yaml
services:
  app:
    ports:
      - "8080:80"  # 将 Web 端口改为 8080

  mysql:
    ports:
      - "3307:3306"  # 将 MySQL 端口改为 3307
```

### 8. 生产环境安全建议

- [ ] 禁用 `APP_DEBUG`
- [ ] 修改默认数据库密码 (docker-compose.yml 中的 `MYSQL_ROOT_PASSWORD`)
- [ ] 配置防火墙,仅开放必要端口
- [ ] 使用 Nginx/Apache 反向代理并配置 SSL 证书
- [ ] 定期备份数据库和上传文件
- [ ] 配置日志监控

---

## 生产环境代码更新

当本地代码有更新需要同步到生产服务器时,按照以下流程操作。

### 更新前准备

#### 1. 本地打包代码

在本地项目目录 (如 `E:\Code\yondermedia`) 执行:

```bash
# Windows PowerShell
cd E:\Code\yondermedia

# 确保依赖是最新的
composer install

# 打包代码 (包含 vendor,避免服务器网络问题)
zip -r sylius.zip . `
  -x ".env.local" `
  -x "docker-compose.yml" `
  -x "compose.override.yml" `
  -x "config/packages/framework.yaml" `
  -x ".docker/dev/Dockerfile" `
  -x "node_modules/*" `
  -x "var/cache/*" `
  -x "var/log/*" `
  -x "public/media/*" `
  -x "public/bundles/*" `
  -x ".git/*"
```

**⚠️ 重要: 必须排除的文件**

| 文件/目录 | 原因 |
|---------|------|
| `.env.local` | 生产环境有独立的环境配置 (APP_ENV=prod) |
| `docker-compose.yml` | 可能有生产环境特定端口配置 |
| `framework.yaml` | 可能有生产环境特定的 trusted_proxies 配置 |
| `Dockerfile` | 避免覆盖生产环境镜像配置 |
| `var/cache/*`, `var/log/*` | 避免覆盖生产环境缓存和日志 |
| `public/media/*` | 避免覆盖用户上传的文件 |
| `node_modules/*` | 服务器端重新安装 |

#### 2. 上传到服务器

```bash
# 方式1: 使用 scp 上传
scp sylius.zip user@your-server:/var/www/sylius/

# 方式2: 使用 SFTP/FTP 客户端上传到 /var/www/sylius/
```

### 标准更新流程

SSH 登录到生产服务器后执行:

```bash
# 1. 进入项目目录
cd /var/www/sylius

# 2. 备份当前代码 (可选但强烈推荐)
zip -r ../sylius-backup-$(date +%Y%m%d-%H%M%S).zip .

# 3. 确保目录权限正确
sudo chown -R $USER:$USER /var/www/sylius

# 4. 解压覆盖
unzip -o sylius.zip

# 5. 删除压缩包
rm sylius.zip

# 6. 重新安装依赖 (如果 composer.json 有变化)
docker compose exec app composer install --no-dev --optimize-autoloader --no-scripts

# 7. 优化 Composer 自动加载 (关键!提升性能 10-50 倍)
docker compose exec app composer dump-autoload --optimize --classmap-authoritative

# 8. 更新前端依赖
docker compose exec app yarn install

# 9. 重新编译前端资源 (生产模式)
docker compose exec app yarn encore production

# 10. 执行数据库迁移 (如果有新迁移)
docker compose exec app php bin/console doctrine:migrations:migrate --no-interaction

# 11. 清理并预热缓存 (关键!提升首次访问速度 5-20 倍)
docker compose exec app rm -rf var/cache/prod/*
docker compose exec app php bin/console cache:warmup --env=prod

# 12. 修复文件权限
docker compose exec app chown -R www-data:www-data var/ public/

# 13. 重启容器 (清空 Opcache 缓存)
docker compose restart app
```

### 一键更新脚本

```bash
cd /var/www/sylius && \
sudo chown -R $USER:$USER /var/www/sylius && \
unzip -o sylius.zip && \
rm sylius.zip && \
docker compose exec app composer install --no-dev --optimize-autoloader --no-scripts && \
docker compose exec app composer dump-autoload --optimize --classmap-authoritative && \
docker compose exec app yarn install && \
docker compose exec app yarn encore production && \
docker compose exec app php bin/console doctrine:migrations:migrate --no-interaction && \
docker compose exec app rm -rf var/cache/prod/* && \
docker compose exec app php bin/console cache:warmup --env=prod && \
docker compose exec app chown -R www-data:www-data var/ public/ && \
docker compose restart app
```

### 轻量级更新 (仅代码修改,无依赖变化)

如果只修改了 PHP/Twig 代码,没有改动 `composer.json`、`package.json`:

```bash
cd /var/www/sylius && \
sudo chown -R $USER:$USER /var/www/sylius && \
unzip -o sylius.zip && \
rm sylius.zip && \
docker compose exec app composer dump-autoload --optimize --classmap-authoritative && \
docker compose exec app rm -rf var/cache/prod/* && \
docker compose exec app php bin/console cache:warmup --env=prod && \
docker compose exec app chown -R www-data:www-data var/ public/ && \
docker compose restart app
```

### 常见问题处理

#### 问题1: bin/console 权限错误

**错误信息:**
```
exec: "bin/console": permission denied
```

**解决方案:**
```bash
# 添加执行权限
docker compose exec app chmod +x bin/console

# 或使用 php 直接执行
docker compose exec app php bin/console cache:clear --env=prod
```

#### 问题2: Windows 换行符问题

**错误信息:**
```
env: 'php\r': No such file or directory
```

**解决方案:**
```bash
# 方式1: 安装并使用 dos2unix
docker compose exec app apt-get update
docker compose exec app apt-get install -y dos2unix
docker compose exec app dos2unix bin/console

# 方式2: 使用 sed 转换
docker compose exec app sed -i 's/\r$//' bin/console

# 方式3: 直接用 php 执行 (推荐)
docker compose exec app php bin/console cache:clear --env=prod
```

#### 问题3: Composer 依赖安装慢或超时

**原因:** GitHub 下载慢或需要 SSH 认证

**解决方案:**
```bash
# 进入容器
docker compose exec app bash

# 添加 GitHub 信任
ssh-keyscan github.com >> ~/.ssh/known_hosts

# 使用国内镜像加速
composer config -g repos.packagist composer https://mirrors.aliyun.com/composer/

# 重新安装
composer clear-cache
composer install --no-dev --optimize-autoloader --no-scripts

# 退出容器
exit
```

#### 问题4: symfony/runtime 缺失

**错误信息:**
```
Fatal error: Uncaught LogicException: Symfony Runtime is missing
```

**解决方案:**
```bash
# 删除旧依赖重新安装
docker compose exec app rm -rf vendor/
docker compose exec app composer install --no-scripts
```

#### 问题5: public/assets/ 目录下文件缺失 (如 UEditor)

**问题:** 解压后发现 `public/assets/ueditor/` 等静态资源文件不存在

**原因:**
1. 打包时可能排除了 `public/assets/` 目录
2. 解压时权限不足,部分文件未解压成功

**解决方案:**

```bash
# 方式1: 单独上传静态资源目录
# 本地打包
cd E:\Code\yondermedia
zip -r assets.zip public/assets/

# 上传并解压
scp assets.zip user@your-server:/var/www/sylius/
ssh user@your-server
cd /var/www/sylius
sudo chown -R $USER:$USER /var/www/sylius
unzip -o assets.zip
rm assets.zip
docker compose exec app chown -R www-data:www-data public/assets/

# 方式2: 重新打包时确保包含 public/assets/
# 修改打包命令,不排除 public/assets/
zip -r sylius.zip . \
  -x ".env.local" \
  -x "docker-compose.yml" \
  -x "node_modules/*" \
  -x "var/cache/*" \
  -x "var/log/*" \
  -x "public/media/*" \      # 只排除 media
  -x "public/bundles/*" \    # 只排除 bundles
  -x ".git/*"
  # public/assets/ 会被保留

# 方式3: 使用 sudo 确保权限正确
cd /var/www/sylius
sudo chown -R $USER:$USER /var/www/sylius
unzip -o sylius.zip
docker compose exec app chown -R www-data:www-data public/
```

**验证:**
```bash
# 检查文件是否存在
ls -la /var/www/sylius/public/assets/ueditor/
docker compose exec app ls -la /app/public/assets/ueditor/

# 测试访问
curl -I http://your-domain.com/assets/ueditor/ueditor.config.js
```

#### 问题6: 更新后访问慢

**原因:** 缓存未优化、自动加载未优化

**解决方案 (关键优化步骤):**
```bash
# 1. 禁用 Blackfire 警告
docker compose exec app rm -f /usr/local/etc/php/conf.d/docker-php-ext-blackfire.ini

# 2. 优化 Composer 自动加载 (关键!)
docker compose exec app composer dump-autoload --optimize --classmap-authoritative

# 3. 清理并预热缓存
docker compose exec app rm -rf var/cache/prod/*
docker compose exec app php bin/console cache:warmup --env=prod

# 4. 修复权限
docker compose exec app chown -R www-data:www-data var/ public/

# 5. 重启容器清空 Opcache
docker compose restart app
```

**性能优化说明:**

| 优化项 | 作用 | 性能提升 |
|-------|------|---------|
| `composer dump-autoload --optimize --classmap-authoritative` | 生成优化的类映射表,不再扫描文件系统 | 类加载速度提升 10-50 倍 |
| `cache:warmup --env=prod` | 预生成所有路由、模板、容器缓存 | 首次访问速度提升 5-20 倍 |
| `docker compose restart app` | 清空 Opcache,重新加载新代码 | 避免使用旧的字节码缓存 |

### 更新验证

```bash
# 1. 检查容器状态
docker compose ps

# 2. 查看应用日志
docker compose logs -f --tail=50 app

# 3. 验证环境配置
docker compose exec app php bin/console about

# 应该显示:
# Environment: prod
# Debug: false
# OPcache: Enabled

# 4. 测试页面响应时间
time curl -s http://your-domain.com/admin/ -o /dev/null -w "Time: %{time_total}s\n"

# 5. 检查数据库同步
docker compose exec app php bin/console doctrine:schema:validate
```

### 更新后数据备份

```bash
# 备份数据库
docker compose exec mysql mysqldump -uroot -pmysql sylius_prod > backup-$(date +%Y%m%d).sql

# 备份上传文件
tar -czf media-backup-$(date +%Y%m%d).tar.gz public/media/
```

### 回滚操作 (如果更新失败)

```bash
# 1. 停止容器
docker compose down

# 2. 恢复代码
cd /var/www
rm -rf sylius
unzip sylius-backup-YYYYMMDD-HHMMSS.zip -d sylius

# 3. 恢复数据库 (如果需要)
docker compose up -d mysql
sleep 10
docker compose exec mysql mysql -uroot -pmysql sylius_prod < backup-YYYYMMDD.sql

# 4. 重启所有服务
docker compose up -d
```

---

## Docker 镜像管理

### 离线部署 - 导出镜像

适用于无法访问外网的服务器。

#### 1. 在有网络的机器上导出镜像

```bash
# 拉取所有需要的镜像
docker pull php:8.2-fpm
docker pull composer:latest
docker pull mysql:5.7
docker pull mailhog/mailhog
docker pull blackfire/blackfire:2

# 导出镜像为 tar 文件
docker save php:8.2-fpm -o php-8.2-fpm.tar
docker save composer:latest -o composer-latest.tar
docker save mysql:5.7 -o mysql-5.7.tar
docker save mailhog/mailhog -o mailhog.tar
docker save blackfire/blackfire:2 -o blackfire.tar

# 查看文件大小
ls -lh *.tar
```

#### 2. 上传到服务器

```bash
# 使用 scp 上传
scp *.tar user@server:/tmp/

# 或使用其他传输方式 (FTP, U盘等)
```

#### 3. 在服务器上导入镜像

```bash
# 导入所有镜像
docker load -i /tmp/php-8.2-fpm.tar
docker load -i /tmp/composer-latest.tar
docker load -i /tmp/mysql-5.7.tar
docker load -i /tmp/mailhog.tar
docker load -i /tmp/blackfire.tar

# 验证镜像已导入
docker images

# 清理 tar 文件
rm /tmp/*.tar
```

### 重新构建镜像

```bash
# 完全重新构建 (不使用缓存)
docker compose build --no-cache

# 重新构建并启动
docker compose up -d --build
```

---

## 常用管理命令

### Makefile 命令

| 命令 | 说明 |
|------|------|
| `make init` | 完整初始化: 安装依赖 + 数据库 + 前端 |
| `make install` | 仅安装 Composer 依赖 |
| `make backend` | 初始化数据库和加载示例数据 |
| `make frontend` | 安装并编译前端资源 (生产模式) |
| `make phpunit` | 运行单元测试 |
| `make phpstan` | 运行静态代码分析 |

### 容器管理

```bash
# 启动所有容器
docker compose up -d

# 停止所有容器
docker compose down

# 重启特定容器
docker compose restart app

# 查看容器状态
docker compose ps

# 查看实时日志
docker compose logs -f app

# 查看最近 50 行日志
docker compose logs --tail=50 app

# 进入容器 Shell
docker compose exec app bash
```

### 用户管理

```bash
# 创建管理员
docker compose exec app bin/console sylius:admin-user:create

# 修改管理员密码
docker compose exec app bin/console sylius:admin-user:change-password

# 提升用户为超级管理员
docker compose exec app bin/console sylius:user:promote

# 降级超级管理员
docker compose exec app bin/console sylius:user:demote
```

### 数据库管理

```bash
# 创建数据库
docker compose exec app bin/console doctrine:database:create

# 查看迁移状态
docker compose exec app bin/console doctrine:migrations:status

# 执行数据库迁移
docker compose exec app bin/console doctrine:migrations:migrate

# 加载示例数据 (会清空现有数据!)
docker compose exec app bin/console sylius:fixtures:load default --no-interaction

# 查看可用的示例数据集
docker compose exec app bin/console sylius:fixtures:list

# 清空数据库 (危险操作!)
docker compose exec app bin/console doctrine:schema:drop --full-database --force

# 重建数据库结构
docker compose exec app bin/console doctrine:schema:create
```

### 完全重置数据库流程

```bash
# 方式1: 使用示例数据重置 (推荐测试环境)
docker compose exec app bin/console doctrine:schema:drop --full-database --force
docker compose exec app bin/console doctrine:schema:create
docker compose exec app bin/console sylius:fixtures:load default --no-interaction
docker compose exec app bin/console sylius:admin-user:create

# 方式2: 空数据库重置 (推荐生产环境)
docker compose exec app bin/console doctrine:schema:drop --full-database --force
docker compose exec app bin/console doctrine:schema:create
docker compose exec app bin/console doctrine:migrations:migrate --no-interaction
docker compose exec app bin/console sylius:admin-user:create
```

### 缓存管理

```bash
# 清空应用缓存
docker compose exec app bin/console cache:clear

# 预热缓存 (生产环境推荐)
docker compose exec app bin/console cache:warmup

# 清空图片缓存
docker compose exec app bin/console liip:imagine:cache:remove

# 清空特定环境缓存
docker compose exec app bin/console cache:clear --env=prod
```

### 前端资源管理

```bash
# 安装前端依赖
docker compose exec app yarn install

# 开发模式编译 (快速)
docker compose exec app yarn build

# 生产模式编译 (压缩优化)
docker compose exec app yarn encore production

# 监听文件变化自动编译 (开发推荐)
docker compose exec app yarn watch
```

### 文件权限管理

```bash
# 在容器内修复权限
docker compose exec app chown -R www-data:www-data /app/var /app/public/media
docker compose exec app chmod -R 775 /app/var /app/public/media

# 或在容器外执行
docker compose exec app bash -c "chown -R www-data:www-data var/ public/media/ && chmod -R 775 var/ public/media/"
```

---

## 故障排查

### 1. 端口冲突

**问题**: `make init` 失败,提示端口已被占用

**解决方案**:

```bash
# 检查端口占用
lsof -i :80    # Web 端口
lsof -i :3306  # MySQL 端口
lsof -i :8025  # Mailhog 端口

# 方式1: 停止冲突服务
sudo systemctl stop apache2  # 停止 Apache
sudo systemctl stop nginx    # 停止 Nginx
sudo systemctl stop mysql    # 停止本地 MySQL

# 方式2: 修改端口 (创建 compose.override.yml)
cat > compose.override.yml <<EOF
services:
  app:
    ports:
      - "8080:80"
  mysql:
    ports:
      - "3307:3306"
  mailhog:
    ports:
      - "8026:8025"
EOF

# 重新启动
docker compose down
docker compose up -d
```

### 2. 文件上传权限错误

**问题**: 无法上传图片,`public/media/` 权限不足

**解决方案**:

```bash
# 进入容器修复权限
docker compose exec app bash
chown -R www-data:www-data /app/public/media
chmod -R 775 /app/public/media
exit

# 或直接执行
docker compose exec app chown -R www-data:www-data /app/public/media
docker compose exec app chmod -R 775 /app/public/media
```

### 3. 前端资源编译失败

**问题**: `yarn build` 失败,提示找不到 Node.js 或 Yarn

**解决方案**:

检查 Dockerfile 是否包含 Node.js 安装:

```dockerfile
# 应该包含以下内容
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn
```

如果缺失,需要重新构建镜像:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

**临时解决方案** (容器重启后失效):

```bash
docker compose exec app bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g yarn
exit

# 然后重新编译
docker compose exec app yarn install
docker compose exec app yarn build
```

### 4. 数据库连接失败 / make init 失败

**问题**: 首次部署时 `make init` 失败，提示：
- "SQLSTATE[HY000] [2002] Connection refused"
- "Database 'sylius_dev' doesn't exist"
- "An exception occurred in driver: could not find driver"

**根本原因**: MySQL 容器启动需要时间（特别是首次启动），但 `make init` 立即执行导致数据库还未就绪。

**解决方案**:

```bash
# 方案1: 等待后重新执行 (最简单)
sleep 15
docker compose exec app make init

# 方案2: 检查 MySQL 状态后再执行
# 1. 检查 MySQL 容器是否运行
docker compose ps mysql

# 2. 等待 MySQL 完全就绪 (看到 "ready for connections")
docker compose exec mysql mysql -uroot -pmysql -e "SHOW DATABASES;"
docker compose logs mysql | grep "ready for connections"

# 3. 手动测试 MySQL 连接
docker compose exec mysql mysqladmin ping -h localhost -proot

# 4. 如果 MySQL 就绪，重新执行初始化
docker compose exec app make init

# 方案3: 分步执行并监控
docker compose exec app make install   # 安装依赖
sleep 5
docker compose exec app make backend    # 初始化数据库
sleep 5
docker compose exec app make frontend   # 编译前端
```

**预防措施**（推荐）:

在 `docker-compose.yml` 中添加 MySQL 健康检查：

```yaml
mysql:
    image: mysql:5.7
    healthcheck:
        test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-proot"]
        interval: 5s
        timeout: 3s
        retries: 10
        start_period: 30s

app:
    depends_on:
        mysql:
            condition: service_healthy  # 确保 MySQL 就绪后再启动
```

### 5. Composer 依赖安装慢

**问题**: 国内网络访问 Packagist 速度慢

**解决方案**:

```bash
# 使用阿里云镜像
docker compose exec app composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 或使用腾讯云镜像
docker compose exec app composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer/

# 重新安装
docker compose exec app composer install
```

### 6. 查看应用日志

```bash
# Symfony 生产环境日志
docker compose exec app tail -100 /app/var/log/prod.log

# Symfony 开发环境日志
docker compose exec app tail -100 /app/var/log/dev.log

# Nginx 访问日志
docker compose exec app tail -100 /var/log/nginx/access.log

# Nginx 错误日志
docker compose exec app tail -100 /var/log/nginx/error.log

# PHP-FPM 错误日志
docker compose logs app | grep php-fpm
```

### 7. 清理 Docker 资源

```bash
# 停止并删除所有容器
docker compose down

# 删除未使用的镜像
docker image prune -a

# 删除未使用的卷 (会删除数据库数据!)
docker volume prune

# 完全清理 (危险!)
docker system prune -a --volumes
```

### 8. 容器无法启动

**问题**: 容器启动后立即退出

**解决方案**:

```bash
# 查看容器退出原因
docker compose ps -a

# 查看容器日志
docker compose logs app

# 尝试手动启动容器查看错误
docker compose up app

# 检查 Dockerfile 和 docker-compose.yml 语法
docker compose config
```

### 9. 使用宿主机 Nginx 反向代理后图片无法显示

**问题**: 部署宿主机 Nginx 反向代理后，图片返回 404 错误

**症状**:
- 图片 URL：`http://IP:8090/media/cache/resolve/...` 返回 404
- 直接访问容器：`http://127.0.0.1:8080/media/...` 返回 302 重定向
- 重定向的 Location 头中的域名/端口不正确

**根本原因**:

1. **Nginx 配置缺少 `/media/` 路径处理**
2. **`proxy_set_header Host` 配置不正确**（应该是 `localhost` 而不是 `$host`）
3. **Symfony 不信任反向代理的 HTTP 头**，导致生成错误的重定向 URL

**解决方案**:

#### A. 修改宿主机 Nginx 配置

编辑 `/etc/nginx/sites-available/sylius-ports.conf`：

```nginx
server {
    listen 8090;
    server_name _;

    # 1. 添加 /media/ 路径处理（关键！）
    location ~* ^/media/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host localhost;  # 必须是 localhost，匹配容器内 Nginx
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        proxy_connect_timeout 60;
        proxy_send_timeout 120;
        proxy_read_timeout 120;
    }

    # 2. 所有其他请求也需要修改 Host 头
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host localhost;  # 必须是 localhost
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        proxy_connect_timeout 60;
        proxy_send_timeout 60;
        proxy_read_timeout 60;
    }
}
```

重载 Nginx：
```bash
sudo nginx -t
sudo systemctl reload nginx
```

#### B. 配置 Symfony Trusted Proxies

编辑 `/var/www/sylius/.env.local`，添加：

```bash
cat >> .env.local << 'EOF'

###> symfony/framework-bundle trusted proxies ###
TRUSTED_PROXIES=127.0.0.1,REMOTE_ADDR
TRUSTED_HOSTS='^(localhost|YOUR_SERVER_IP)$'
###< symfony/framework-bundle trusted proxies ###
EOF
```

或者编辑 `config/packages/framework.yaml`：

```yaml
framework:
    # ... 其他配置
    trusted_proxies: '127.0.0.1,REMOTE_ADDR'
    trusted_headers: ['x-forwarded-for', 'x-forwarded-host', 'x-forwarded-proto', 'x-forwarded-port']
```

清空缓存并重启：
```bash
docker compose exec app bin/console cache:clear --env=prod
docker compose restart app
```

#### C. 验证修复

```bash
# 1. 测试直接访问容器（应该返回 302 重定向）
curl -I http://127.0.0.1:8080/media/cache/resolve/sylius_shop_product_thumbnail/path/to/image.webp

# 检查 Location 头应该包含正确的域名和端口：
# Location: http://YOUR_IP:8090/media/cache/...

# 2. 测试通过宿主机 Nginx 访问
curl -I http://YOUR_IP:8090/media/cache/resolve/sylius_shop_product_thumbnail/path/to/image.webp

# 3. 浏览器测试
# 访问前台，图片应该正常显示
```

**关键知识点**:

| 配置项 | 作用 | 错误配置 | 正确配置 |
|--------|------|----------|----------|
| `proxy_set_header Host` | 传递给容器的 Host 头 | `$host`（172.17.3.80:8090） | `localhost` |
| `TRUSTED_PROXIES` | Symfony 信任的代理 IP | 未配置 | `127.0.0.1,REMOTE_ADDR` |
| `TRUSTED_HEADERS` | 信任的 HTTP 头 | 未配置 | `x-forwarded-*` 系列 |
| `location ~* ^/media/` | 处理媒体文件请求 | 缺失 | 必须配置 |

**原理说明**:

1. **容器内 Nginx 配置**：`server_name localhost;`（只匹配 localhost）
2. **宿主机 Nginx** 必须传递 `Host: localhost`，否则容器内 Nginx 无法匹配
3. **Sylius 图片处理流程**：
   - 首次访问：`/media/cache/resolve/filter/path` → Symfony 生成缩略图
   - 302 重定向：`Location: /media/cache/filter/path`（缓存路径）
   - 后续访问：直接返回缓存文件
4. **Trusted Proxies** 让 Symfony 正确识别真实的域名/端口，生成正确的重定向 URL

---

### 10. Nginx 反向代理后访问速度变慢

**问题**: 部署宿主机 Nginx 反向代理后，页面加载速度明显变慢

**症状**:
- 直接访问容器 `http://127.0.0.1:8080` 速度正常
- 通过宿主机 Nginx `http://IP:8090` 访问明显变慢
- 页面加载时间从 200ms 增加到 1-2 秒

**根本原因**:

1. **未启用 HTTP/1.1 持久连接** - 每次请求都重新建立 TCP 连接
2. **代理缓冲未优化** - 默认缓冲区太小，导致频繁磁盘 I/O
3. **未启用 Gzip 压缩** - 传输数据量大
4. **静态资源未缓存** - CSS/JS/图片每次都经过代理转发

**解决方案**:

#### A. 优化 Nginx 反向代理配置

编辑 `/etc/nginx/sites-enabled/sylius-ports.conf`（或 `nginx-configs/sylius-ports.conf`）：

```nginx
server {
    listen 8090;
    server_name _;

    # 客户端缓冲区设置
    client_max_body_size 20M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;

    # ========== 性能优化：Gzip 压缩 ==========
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";
    gzip_min_length 1000;

    location ~* ^/media/ {
        proxy_pass http://127.0.0.1:8080;

        # 性能优化：启用 HTTP/1.1 持久连接
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # 请求头设置
        proxy_set_header Host localhost;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        # 性能优化：启用代理缓冲
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        proxy_temp_file_write_size 8k;

        proxy_connect_timeout 60;
        proxy_send_timeout 120;
        proxy_read_timeout 120;
    }

    # 静态资源长期缓存
    location ~* ^/build/.*\.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|map)$ {
        proxy_pass http://127.0.0.1:8080;

        # 性能优化
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host localhost;

        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;

        # 长期缓存
        expires 365d;
        add_header Cache-Control "public, immutable";

        # 忽略后端的缓存控制头
        proxy_ignore_headers "Set-Cookie" "Cache-Control" "Expires";
        proxy_hide_header "Set-Cookie";
    }

    location / {
        proxy_pass http://127.0.0.1:8080;

        # 性能优化：启用 HTTP/1.1 持久连接
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        proxy_set_header Host localhost;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        # 性能优化：启用代理缓冲
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 24 4k;
        proxy_busy_buffers_size 8k;
        proxy_temp_file_write_size 8k;

        proxy_connect_timeout 60;
        proxy_send_timeout 60;
        proxy_read_timeout 60;
    }
}
```

**应用配置**:

```bash
# 1. 备份原配置
sudo cp /etc/nginx/sites-enabled/sylius-ports.conf /etc/nginx/sites-enabled/sylius-ports.conf.backup

# 2. 如果配置在 nginx-configs/ 目录，复制过去
sudo cp /var/www/sylius/nginx-configs/sylius-ports.conf /etc/nginx/sites-enabled/sylius-ports.conf

# 3. 测试配置
sudo nginx -t

# 4. 重载 Nginx
sudo systemctl reload nginx

# 5. 验证状态
sudo systemctl status nginx
```

**性能对比测试**:

```bash
# 优化前测试
time curl -s http://your_ip:8090/ > /dev/null

# 优化后测试（应该快 30-50%）
time curl -s http://your_ip:8090/ > /dev/null

# 查看压缩效果
curl -I -H "Accept-Encoding: gzip" http://your_ip:8090/
# 应该看到: Content-Encoding: gzip
```

**优化效果**:
- ✅ 页面加载速度提升 30-50%
- ✅ 带宽使用减少 60-70%（Gzip 压缩）
- ✅ 静态资源缓存命中，减少后端压力
- ✅ HTTP 持久连接减少 TCP 握手开销

---

### 11. 后台创建产品页面 500 错误（缓存目录权限问题）

**问题**: 访问后台创建产品页面 `/admin/products/new/simple` 返回 500 错误

**症状**:
- 页面显示 "Oops! An Error Occurred" 500 Internal Server Error
- 其他页面正常访问
- 前台商城正常

**错误日志**:

```
Uncaught PHP Exception RuntimeException:
"Unable to write in the cache directory (/app/var/cache/prod/twig/a2)."
```

**根本原因**:

1. **`/app/var/cache` 目录权限不足** - www-data 用户无法写入 Twig 缓存
2. **生产环境首次访问** - Twig 需要编译模板并写入缓存
3. **Docker 容器内外权限不一致** - 宿主机和容器的 UID/GID 映射问题

**解决方案**:

#### 完整权限修复流程

```bash
cd /var/www/sylius

# 1. 停止容器（可选，但推荐）
docker compose stop app

# 2. 在宿主机删除旧缓存
sudo rm -rf var/cache/*
sudo rm -rf var/log/*

# 3. 重新创建目录并设置权限（关键步骤）
sudo mkdir -p var/cache/prod var/log
sudo chown -R 33:33 var/cache var/log public/media
sudo chmod -R 775 var/cache var/log public/media

# 注意：33:33 是 www-data 的 UID:GID

# 4. 启动容器
docker compose start app

# 5. 在容器内部再次确认权限
docker compose exec app chown -R www-data:www-data /app/var /app/public/media
docker compose exec app chmod -R 775 /app/var /app/public/media

# 6. 清空并预热缓存
docker compose exec app bin/console cache:clear --env=prod --no-debug
docker compose exec app bin/console cache:warmup --env=prod --no-debug

# 7. 验证权限（应该显示 www-data www-data）
docker compose exec app ls -la /app/var/cache/
docker compose exec app ls -la /app/var/log/
```

#### 快速修复（如果容器已运行）

```bash
cd /var/www/sylius

# 1. 删除缓存
docker compose exec app rm -rf /app/var/cache/*

# 2. 修复权限
docker compose exec app chown -R www-data:www-data /app/var /app/public/media /app/config
docker compose exec app chmod -R 775 /app/var /app/public/media

# 3. 重新生成缓存
docker compose exec app bin/console cache:clear --env=prod --no-debug
docker compose exec app bin/console cache:warmup --env=prod --no-debug

# 4. 重启容器
docker compose restart app
```

#### 验证修复

```bash
# 1. 检查目录权限
docker compose exec app ls -la /app/var/

# 输出示例（正确）：
# drwxrwxr-x 5 www-data www-data 4096 Oct 15 04:00 cache
# drwxrwxr-x 2 www-data www-data 4096 Oct 15 04:00 log

# 2. 检查缓存是否可写
docker compose exec app touch /app/var/cache/test.txt
docker compose exec app rm /app/var/cache/test.txt
# 如果没有报错，说明权限正确

# 3. 访问页面测试
curl -I http://your_ip:8091/admin/products/new/simple
# 应该返回 200 OK

# 4. 查看日志确认没有新错误
docker compose exec app tail -20 /app/var/log/prod.log
```

#### 预防措施（生产环境部署时执行）

```bash
# 在首次部署或更新代码后执行

cd /var/www/sylius

# 1. 确保目录存在
sudo mkdir -p var/cache var/log public/media

# 2. 统一设置权限
sudo chown -R 33:33 var/ public/media/
sudo chmod -R 775 var/ public/media/

# 3. 进入容器确认
docker compose exec app chown -R www-data:www-data /app/var /app/public/media
docker compose exec app chmod -R 775 /app/var /app/public/media

# 4. 清空缓存
docker compose exec app bin/console cache:clear --env=prod
docker compose exec app bin/console cache:warmup --env=prod
```

**权限说明**:

| UID/GID | 用户 | 说明 |
|---------|------|------|
| 33:33 | www-data | 容器内 Nginx/PHP-FPM 运行用户 |
| 775 | rwxrwxr-x | 所有者和组可读写执行，其他人可读执行 |

**为什么使用 33:33？**
- Docker 容器内 www-data 用户的 UID=33, GID=33
- 在宿主机设置为 33:33，容器内就是 www-data
- 确保容器内外权限一致

**常见权限错误**:

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `Unable to write in the cache directory` | 缓存目录无写权限 | `chown 33:33 var/cache` |
| `Failed to write log file` | 日志目录无写权限 | `chown 33:33 var/log` |
| `Unable to create directory` | 父目录权限不足 | `chmod 775 var/` |
| `Permission denied` | 目录所有者不是 www-data | `chown -R www-data:www-data /app/var` |

**故障排查命令**:

```bash
# 查看哪个用户运行 PHP-FPM
docker compose exec app ps aux | grep php-fpm

# 查看当前目录权限
docker compose exec app ls -lan /app/var/

# 查看 Symfony 环境信息
docker compose exec app bin/console about

# 实时监控日志
docker compose logs app -f
# 然后访问页面，观察日志输出
```

---

## 常见场景速查

### 场景1: 本地开发环境快速搭建

```bash
# 克隆项目
git clone https://github.com/Sylius/Sylius.git sylius
cd sylius

# 检查配置（确保是开发环境）
# - 删除 .env.local 文件（如果存在）
# - 修改 docker-compose.yml 中 APP_ENV 为 "dev"

# 启动并初始化
docker compose up -d
sleep 15  # 首次部署等待 MySQL 启动
docker compose exec app make init

# 创建管理员
docker compose exec app bin/console sylius:admin-user:create

# 访问 http://localhost
```

### 场景2: 生产服务器首次部署

```bash
# 1. 上传代码到服务器
cd /var/www/sylius

# 2. 修改 .env.local 为生产配置
nano .env.local  # 设置 APP_ENV=prod, APP_DEBUG=0

# 3. 修改 docker-compose.yml
nano docker-compose.yml  # 确保 APP_ENV="prod"

# 4. 构建并启动
docker compose build --no-cache
docker compose up -d

# 5. 等待 MySQL 完全启动 (首次部署关键步骤!)
sleep 15
docker compose logs mysql | tail -20  # 查看是否出现 "ready for connections"

# 6. 初始化 (如果失败，再等待 10 秒重新执行)
docker compose exec app make init

# 7. 创建管理员
docker compose exec app bin/console sylius:admin-user:create

# 8. 优化生产环境
docker compose exec app yarn encore production
docker compose exec app bin/console cache:warmup --env=prod
```

### 场景3: 更新代码并重新部署

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 停止容器
docker compose down

# 3. 重新构建
docker compose build --no-cache
docker compose up -d

# 4. 更新依赖和数据库
docker compose exec app composer install
docker compose exec app bin/console doctrine:migrations:migrate --no-interaction
docker compose exec app yarn install
docker compose exec app yarn encore production

# 5. 清理缓存
docker compose exec app bin/console cache:clear --env=prod
```

### 场景4: 数据库备份与恢复

```bash
# 备份数据库
docker compose exec mysql mysqldump -uroot -pmysql sylius_prod > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker compose exec -T mysql mysql -uroot -pmysql sylius_prod < backup_20231215.sql
```

---

## 图片上传与缩略图机制详解

### 📸 图片处理架构概览

Sylius 使用 **LiipImagineBundle** 实现图片上传、存储和动态缩略图生成。

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  用户上传图片    │────▶│  ImageUploader   │────▶│  存储到文件系统  │
│  (后台/API)     │     │  (处理上传)       │     │  public/media/  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  浏览器访问图片  │────▶│  LiipImagine     │────▶│  生成缩略图      │
│  (前台显示)     │     │  (动态处理)       │     │  public/media/  │
└─────────────────┘     └──────────────────┘     │  cache/         │
                                                  └─────────────────┘
```

---

### 🗂️ 文件存储目录结构

#### 1. 原始图片存储位置

**路径**: `public/media/image/`

**配置文件**: `src/Sylius/Bundle/CoreBundle/Resources/config/app/config.yml`

```yaml
parameters:
    sylius_core.public_dir: "%kernel.project_dir%/web"
    sylius_core.images_dir: "%sylius_core.public_dir%/media/image"
```

**实际存储路径**（容器内）:
```
/app/public/media/image/
├── ab/                           # 第1-2位哈希值作为目录
│   └── cd/                       # 第3-4位哈希值作为子目录
│       └── ef1234567890.webp     # 剩余哈希值+扩展名
├── 12/
│   └── 34/
│       └── 567890abcdef.jpeg
└── .gitkeep
```

**路径生成算法**（`UploadedImagePathGenerator.php`）:

```php
// 生成 32 位随机哈希值
$hash = bin2hex(random_bytes(16));  // 例如: abcdef1234567890abcdef1234567890

// 分层存储: ab/cd/ef1234567890abcdef1234567890.webp
$path = sprintf('%s/%s/%s',
    substr($hash, 0, 2),   // 前2位: ab
    substr($hash, 2, 2),   // 中2位: cd
    substr($hash, 4)       // 剩余: ef1234567890abcdef1234567890
);
```

**为什么分层存储？**
- ✅ 避免单个目录文件过多（性能问题）
- ✅ 提高文件系统查询效率
- ✅ 防止广告拦截器误拦截（路径避免包含 "ad" 字符）

#### 2. 缩略图缓存位置

**路径**: `public/media/cache/`

**配置文件**: `src/Sylius/Bundle/CoreBundle/Resources/config/app/config.yml`

```yaml
liip_imagine:
    resolvers:
        sylius_image:
            web_path:
                web_root: "%sylius_core.public_dir%"
                cache_prefix: "media/cache"  # 缓存目录前缀
```

**缓存目录结构**:

```
/app/public/media/cache/
├── resolve/                                      # 动态生成入口（302重定向）
│   ├── sylius_shop_product_thumbnail/           # 按过滤器分类
│   │   └── ab/cd/ef1234567890.webp             # 原始图片路径
│   └── sylius_admin_product_thumbnail/
│       └── 12/34/567890abcdef.jpeg
│
└── sylius_shop_product_thumbnail/               # 实际缓存文件
    ├── ab/cd/ef1234567890.webp                 # 已生成的缩略图
    └── 12/34/567890abcdef.jpeg
```

---

### 🔄 图片上传流程详解

#### 步骤 1: 用户上传图片

**触发方式**:
- 后台管理界面（产品/分类管理）
- API 接口（`POST /api/v2/admin/product-images`）

**上传处理器**: `Sylius\Component\Core\Uploader\ImageUploader`

```php
public function upload(ImageInterface $image): void
{
    // 1. 检查是否有文件
    if (!$image->hasFile()) {
        return;
    }

    // 2. 删除旧图片（如果存在）
    if (null !== $image->getPath() && $this->filesystem->has($image->getPath())) {
        $this->remove($image->getPath());
    }

    // 3. 生成随机路径（避免冲突和广告拦截）
    do {
        $path = $this->imagePathGenerator->generate($image);
    } while ($this->isAdBlockingProne($path) || $this->filesystem->has($path));

    // 4. 保存路径到数据库
    $image->setPath($path);

    // 5. 写入文件系统
    $this->filesystem->write($image->getPath(), file_get_contents($file->getPathname()));
}
```

#### 步骤 2: 文件系统存储

**存储适配器**: `FlysystemFilesystemAdapter`

**配置**: `src/Sylius/Bundle/CoreBundle/Resources/config/app/config.yml`

```yaml
flysystem:
    storages:
        sylius.storage:
            adapter: 'local'
            options:
                directory: '%sylius_core.images_dir%'  # public/media/image
            directory_visibility: 'public'
```

**实际写入位置**（容器内）:
```
/app/public/media/image/ab/cd/ef1234567890abcdef.webp
```

**实际写入位置**（宿主机）:
```
/var/www/sylius/public/media/image/ab/cd/ef1234567890abcdef.webp
```

#### 步骤 3: 数据库记录

**数据表**: `sylius_product_image` / `sylius_taxon_image`

**字段**:
```sql
CREATE TABLE sylius_product_image (
    id INT PRIMARY KEY,
    product_id INT,
    path VARCHAR(255),          -- 存储相对路径: ab/cd/ef1234567890.webp
    type VARCHAR(255),          -- 图片类型: main/thumbnail
    created_at DATETIME,
    updated_at DATETIME
);
```

---

### 🖼️ 缩略图生成流程详解

#### 首次访问流程（动态生成）

**1. 浏览器请求缩略图**

```
用户访问: http://your-ip:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef1234567890.webp
                                          ↑                            ↑
                                    动态生成入口                    过滤器名称
```

**2. Nginx 转发请求到 Symfony**

容器内 Nginx 配置（`Dockerfile`）:
```nginx
location / {
    try_files $uri /index.php$is_args$args;  # 文件不存在时转发到 Symfony
}
```

**3. LiipImagineBundle 处理请求**

**路由**: `config/routes/liip_imagine.yaml`
```yaml
_liip_imagine:
    resource: "@LiipImagineBundle/Resources/config/routing.yaml"
```

**处理流程**:
```php
// 1. 解析请求: /media/cache/resolve/[filter]/[path]
$filter = 'sylius_shop_product_thumbnail';
$path = 'ab/cd/ef1234567890.webp';

// 2. 检查原始文件是否存在
if (!file_exists('/app/public/media/image/' . $path)) {
    return 404;
}

// 3. 应用图片过滤器（缩放、裁剪、转换格式）
$image = $this->imagine->open('/app/public/media/image/' . $path);
$image->thumbnail(new Box(600, 800), ImageInterface::THUMBNAIL_OUTBOUND);
$image->save('/app/public/media/cache/sylius_shop_product_thumbnail/' . $path, [
    'format' => 'webp',
    'quality' => 80
]);

// 4. 302 重定向到缓存文件
return redirect('/media/cache/sylius_shop_product_thumbnail/' . $path);
```

**4. 浏览器请求缓存文件**

```
浏览器重定向到: http://your-ip:8090/media/cache/sylius_shop_product_thumbnail/ab/cd/ef1234567890.webp
                                                 ↑
                                          实际缓存文件路径
```

**5. Nginx 直接返回静态文件**

```nginx
location / {
    try_files $uri /index.php$is_args$args;
    # $uri 匹配成功，直接返回缓存文件，不经过 PHP
}
```

#### 后续访问流程（缓存命中）

```
用户访问缩略图 URL
    ↓
Nginx 检查文件是否存在: public/media/cache/[filter]/[path]
    ↓
存在 → 直接返回静态文件（极快，不经过 PHP）
    ↓
不存在 → 转发到 Symfony 动态生成（首次访问）
```

---

### ⚙️ 图片过滤器配置详解

#### 前台商城过滤器

**配置文件**: `src/Sylius/Bundle/ShopBundle/Resources/config/app/config.yml`

```yaml
liip_imagine:
    filter_sets:
        sylius_shop_product_original: ~  # 原始尺寸，不处理

        sylius_shop_product_small_thumbnail:
            format: webp          # 强制转换为 WebP 格式
            quality: 80           # 质量 80%（平衡大小和清晰度）
            filters:
                thumbnail: { size: [300, 400], mode: outbound }
                # mode: outbound = 裁剪模式（保持比例，超出部分裁剪）

        sylius_shop_product_thumbnail:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [600, 800], mode: outbound }

        sylius_shop_product_large_thumbnail:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [1200, 1600], mode: outbound }

        sylius_shop_taxon_thumbnail:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [1200, 300], mode: outbound }
```

#### 后台管理过滤器

**配置文件**: `src/Sylius/Bundle/AdminBundle/Resources/config/app/config.yml`

```yaml
liip_imagine:
    filter_sets:
        sylius_admin_product_original: ~

        sylius_admin_avatar:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [200, 200], mode: outbound }

        sylius_admin_product_thumbnail:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [200, 200], mode: outbound }

        sylius_admin_product_large_thumbnail:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [600, 800], mode: outbound }
```

#### 核心过滤器（通用）

**配置文件**: `src/Sylius/Bundle/CoreBundle/Resources/config/app/config.yml`

```yaml
liip_imagine:
    cache: sylius_image              # 缓存存储器
    data_loader: sylius_image        # 数据加载器

    loaders:
        sylius_image:
            filesystem:
                data_root: "%sylius_core.images_dir%"  # 读取原始图片的根目录

    resolvers:
        sylius_image:
            web_path:
                web_root: "%sylius_core.public_dir%"   # public/
                cache_prefix: "media/cache"            # 缓存前缀

    filter_sets:
        sylius_original: ~
        sylius_small:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [120, 90], mode: outbound }
        sylius_medium:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [240, 180], mode: outbound }
        sylius_large:
            format: webp
            quality: 80
            filters:
                thumbnail: { size: [640, 480], mode: outbound }
```

---

### 🔍 图片 URL 生成机制

#### API 响应中的图片 URL

**Normalizer**: `Sylius\Bundle\ApiBundle\Serializer\Normalizer\ImageNormalizer`

```php
public function normalize(ImageInterface $object): array
{
    $data = [
        'id' => $object->getId(),
        'type' => $object->getType(),
        'path' => $object->getPath(),  // 数据库中的路径: ab/cd/ef.webp
    ];

    // 自动转换为完整的缩略图 URL
    $filter = $request->query->get('imageFilter', 'sylius_original');
    $data['path'] = $this->cacheManager->getBrowserPath($data['path'], $filter);
    // 结果: /media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp

    return $data;
}
```

#### 模板中的图片显示

**Twig 模板**: `src/Sylius/Bundle/ShopBundle/templates/product/show/content/info/overview/images.html.twig`

```twig
{% for image in product.images %}
    <img src="{{ image.path|imagine_filter('sylius_shop_product_thumbnail') }}"
         alt="{{ product.name }}">
    {# imagine_filter 过滤器会生成:
       /media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp
    #}
{% endfor %}
```

**Twig 过滤器**: `imagine_filter`

```php
// LiipImagineBundle 提供的 Twig 扩展
{{ 'ab/cd/ef.webp'|imagine_filter('sylius_shop_product_thumbnail') }}
// 输出: /media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp
```

---

### 🚀 宿主机 Nginx 反向代理与图片处理

#### 关键配置说明

**为什么图片需要特殊处理？**

Sylius 的图片缩略图采用**按需生成**策略：
1. 首次访问缩略图 URL 时，Symfony 动态生成并返回 **302 重定向**
2. 重定向到实际缓存文件路径
3. 后续访问直接返回缓存文件（Nginx 静态服务）

**宿主机 Nginx 必须正确处理**：
- ✅ 转发 `/media/` 请求到容器
- ✅ 设置正确的 `Host` 头（匹配容器内 Nginx）
- ✅ 配置较长的超时时间（首次生成需要时间）

#### 完整配置示例

**文件**: `nginx-configs/sylius-ports.conf`

```nginx
server {
    listen 8090;  # 前台端口
    server_name _;

    # 客户端上传文件大小限制
    client_max_body_size 20M;

    # ⚠️ 关键配置 1: 处理 /media/ 路径（图片、上传文件等）
    location ~* ^/media/ {
        proxy_pass http://127.0.0.1:8080;

        # ⚠️ 必须设置为 localhost，匹配容器内 Nginx 的 server_name
        proxy_set_header Host localhost;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        # 图片处理超时设置（首次生成需要较长时间）
        proxy_connect_timeout 60;
        proxy_send_timeout 120;   # 上传大图需要更长时间
        proxy_read_timeout 120;   # 生成缩略图需要更长时间
    }

    # 所有其他请求
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host localhost;  # 同样必须是 localhost
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        proxy_connect_timeout 60;
        proxy_send_timeout 60;
        proxy_read_timeout 60;
    }

    # 静态资源缓存优化（编译后的 CSS/JS）
    location ~* ^/build/.*\.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|map)$ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host localhost;
        expires 365d;                     # 缓存 1 年
        add_header Cache-Control "public, immutable";
    }
}
```

#### 为什么必须设置 `Host: localhost`？

**容器内 Nginx 配置**（`.docker/dev/Dockerfile`）:
```nginx
server {
    listen 80;
    server_name localhost;  # ← 只匹配 localhost
    root /app/public;
    # ...
}
```

**问题场景对比**:

| 配置 | Host 头值 | 容器内 Nginx | 结果 |
|-----|----------|-------------|------|
| `proxy_set_header Host $host;` | `172.17.3.80:8090` | ❌ 无法匹配 `server_name localhost` | 返回 404 |
| `proxy_set_header Host localhost;` | `localhost` | ✅ 成功匹配 | 正常处理 |

**详细原理**:
```bash
# 错误配置
❌ proxy_set_header Host $host;
   → 宿主机 Nginx 传递 Host: 172.17.3.80:8090
   → 容器内 Nginx 检查 server_name localhost（不匹配）
   → 找不到对应的 server 块
   → 返回 404 Not Found

# 正确配置
✅ proxy_set_header Host localhost;
   → 宿主机 Nginx 传递 Host: localhost
   → 容器内 Nginx 检查 server_name localhost（匹配）
   → 正常处理请求
   → 返回图片或 302 重定向
```

#### Symfony Trusted Proxies 配置（关键）

**问题**: 即使 Nginx 配置正确，图片 302 重定向的 URL 仍然错误

**症状**:
```bash
# 访问缩略图生成 URL
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp

# 返回 302，但 Location 错误
HTTP/1.1 302 Found
Location: http://localhost:8080/media/cache/sylius_shop_product_thumbnail/ab/cd/ef.webp
          ↑          ↑
    错误：应该是服务器IP    错误：应该是 8090
```

**原因**: Symfony 不信任反向代理的 HTTP 头，无法识别真实的域名和端口

**解决方案**: 配置 Symfony Trusted Proxies

**方式 1: 环境变量**（推荐）

编辑 `.env.local`:
```bash
cat >> .env.local << 'EOF'

###> symfony/framework-bundle trusted proxies ###
TRUSTED_PROXIES=127.0.0.1,REMOTE_ADDR
TRUSTED_HOSTS='^(localhost|172\.17\.3\.80)$'
###< symfony/framework-bundle trusted proxies ###
EOF
```

**方式 2: 配置文件**

编辑 `config/packages/framework.yaml`:
```yaml
framework:
    trusted_proxies: '127.0.0.1,REMOTE_ADDR'
    trusted_headers:
        - 'x-forwarded-for'
        - 'x-forwarded-host'
        - 'x-forwarded-proto'
        - 'x-forwarded-port'
```

**应用配置**:
```bash
# 清空缓存
docker compose exec app bin/console cache:clear --env=prod

# 重启容器
docker compose restart app
```

**验证修复**:
```bash
# 再次测试重定向
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp

# 应该返回正确的 Location
HTTP/1.1 302 Found
Location: http://172.17.3.80:8090/media/cache/sylius_shop_product_thumbnail/ab/cd/ef.webp
          ↑                ↑
      ✅ 正确的服务器IP   ✅ 正确的端口号
```

---

### 🗑️ 缓存管理命令

#### 清空所有图片缓存

```bash
# 方式 1: 使用 Symfony 命令（推荐）
docker compose exec app bin/console liip:imagine:cache:remove

# 方式 2: 手动删除缓存文件
docker compose exec app rm -rf public/media/cache/*

# 方式 3: 清空特定环境的缓存
docker compose exec app bin/console liip:imagine:cache:remove --env=prod
```

**何时需要清空缓存？**
- ✅ 修改了图片过滤器配置
- ✅ 原始图片被替换（但路径相同）
- ✅ 磁盘空间不足
- ✅ 缩略图显示异常

#### 清空特定过滤器缓存

```bash
# 仅清空 sylius_shop_product_thumbnail 的缓存
docker compose exec app bin/console liip:imagine:cache:remove --filter=sylius_shop_product_thumbnail

# 清空多个过滤器
docker compose exec app bin/console liip:imagine:cache:remove \
    --filter=sylius_shop_product_thumbnail \
    --filter=sylius_admin_product_thumbnail
```

#### 清空特定图片缓存

```bash
# 清空指定路径图片的所有过滤器缓存
docker compose exec app bin/console liip:imagine:cache:remove ab/cd/ef1234567890.webp

# 清空多个图片的缓存
docker compose exec app bin/console liip:imagine:cache:remove \
    ab/cd/ef1234567890.webp \
    12/34/567890abcdef.jpeg
```

#### 预生成缓存（生产环境优化）

```bash
# 预生成单个图片的缓存（所有过滤器）
docker compose exec app bin/console liip:imagine:cache:resolve ab/cd/ef1234567890.webp

# 预生成指定过滤器的缓存
docker compose exec app bin/console liip:imagine:cache:resolve ab/cd/ef1234567890.webp \
    --filter=sylius_shop_product_thumbnail

# 批量预生成（需要自定义脚本）
docker compose exec app bash -c '
for image in $(find public/media/image -type f -name "*.webp" | head -10); do
    path=${image#public/media/image/}
    bin/console liip:imagine:cache:resolve "$path" --filter=sylius_shop_product_thumbnail
done
'
```

---

### 📊 图片处理性能优化

#### 1. PHP GD 扩展优化（已配置）

**Dockerfile** 已包含 WebP 支持:

```dockerfile
# 安装 WebP 相关库
RUN apt-get install -y libwebp-dev libjpeg-dev libfreetype6-dev libpng-dev

# 配置 GD 扩展支持 WebP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd
```

**验证 WebP 支持**:
```bash
docker compose exec app php -r "var_dump(function_exists('imagewebp'));"
# 输出: bool(true) ✅

docker compose exec app php -r "print_r(gd_info());"
# 输出应包含: WebP Support => enabled ✅
```

**PHP GD 配置** (`.docker/dev/php.ini`):
```ini
[GD]
memory_limit = 256M              # 处理大图需要足够内存
max_execution_time = 300         # 生成缩略图可能需要时间
```

#### 2. 图片格式转换策略

**优先级**: WebP > JPEG > PNG

**为什么使用 WebP？**
- ✅ 文件大小比 JPEG 小 25-35%
- ✅ 文件大小比 PNG 小 50-80%
- ✅ 支持透明背景（替代 PNG）
- ✅ 现代浏览器广泛支持

**配置**（所有过滤器默认使用 WebP）:
```yaml
liip_imagine:
    filter_sets:
        sylius_shop_product_thumbnail:
            format: webp      # 强制转换为 WebP
            quality: 80       # 质量 80%（平衡大小和清晰度）
            filters:
                thumbnail: { size: [600, 800], mode: outbound }
```

**格式转换示例**:
```
原始文件: product.jpg (500 KB)
    ↓
生成缩略图: ab/cd/ef123.webp (150 KB)  ← 节省 70% 空间
```

**兼容性处理**:
- Chrome, Edge, Firefox, Opera: ✅ 原生支持 WebP
- Safari 14+, iOS 14+: ✅ 原生支持 WebP
- IE 11, 旧版 Safari: ❌ 不支持（Sylius 会回退到 JPEG）

#### 3. 缓存优化策略

**静态资源缓存**（宿主机 Nginx）:
```nginx
# 编译后的 CSS/JS 文件（版本化，可以长期缓存）
location ~* ^/build/.*\.(css|js|map)$ {
    proxy_pass http://127.0.0.1:8080;
    expires 365d;                           # 缓存 1 年
    add_header Cache-Control "public, immutable";
}

# 字体文件
location ~* ^/build/.*\.(woff|woff2|ttf|eot|svg)$ {
    proxy_pass http://127.0.0.1:8080;
    expires 365d;
    add_header Cache-Control "public, immutable";
}

# 图片缓存（注意：不要对 /media/cache/resolve/ 设置缓存）
location ~* ^/media/cache/(?!resolve).*\.(webp|jpg|jpeg|png|gif)$ {
    proxy_pass http://127.0.0.1:8080;
    expires 30d;                            # 缓存 30 天
    add_header Cache-Control "public";
}
```

**缓存策略总结**:

| 路径 | 缓存时长 | 原因 |
|------|---------|------|
| `/build/shop.*` | 365 天 | 文件名包含哈希值，内容变化会改变文件名 |
| `/media/cache/resolve/` | 不缓存 | 动态生成入口，需要 302 重定向 |
| `/media/cache/[filter]/` | 30 天 | 实际缓存文件，可以长期缓存 |
| `/media/image/` | 不缓存 | 原始图片，一般不直接访问 |

#### 4. 文件权限优化

**确保 www-data 用户有写权限**:
```bash
# 在容器内执行
docker compose exec app chown -R www-data:www-data /app/public/media
docker compose exec app chmod -R 775 /app/public/media

# 或在容器外执行（宿主机）
sudo chown -R 33:33 /var/www/sylius/public/media  # 33 是 www-data 的 UID
sudo chmod -R 775 /var/www/sylius/public/media
```

**验证权限**:
```bash
docker compose exec app ls -la /app/public/media
# 输出应显示:
# drwxrwxr-x 5 www-data www-data 4096 Oct 14 10:00 image
# drwxrwxr-x 3 www-data www-data 4096 Oct 14 10:05 cache
```

**自动修复权限脚本**:
```bash
#!/bin/bash
# fix-media-permissions.sh

echo "修复 public/media 权限..."
docker compose exec app bash -c '
    chown -R www-data:www-data /app/public/media
    chmod -R 775 /app/public/media
    find /app/public/media -type d -exec chmod 775 {} \;
    find /app/public/media -type f -exec chmod 664 {} \;
'
echo "权限修复完成！"
```

#### 5. 磁盘空间优化

**监控磁盘使用**:
```bash
# 查看媒体文件夹大小
docker compose exec app du -sh /app/public/media/image
docker compose exec app du -sh /app/public/media/cache

# 详细统计
docker compose exec app du -sh /app/public/media/*
# 输出示例:
# 2.5G    /app/public/media/image
# 8.3G    /app/public/media/cache

# 统计文件数量
docker compose exec app find /app/public/media/image -type f | wc -l
docker compose exec app find /app/public/media/cache -type f | wc -l
```

**清理策略**:
```bash
# 清理 30 天未访问的缓存文件
docker compose exec app find /app/public/media/cache -type f -atime +30 -delete

# 清理所有缓存（保留原始图片）
docker compose exec app rm -rf /app/public/media/cache/*

# 仅清理特定过滤器的缓存
docker compose exec app rm -rf /app/public/media/cache/sylius_shop_product_large_thumbnail
```

---

### 🛠️ 故障排查：图片无法显示

#### 问题 1: 图片上传后返回 404

**症状**:
- ✅ 后台上传图片成功（显示"上传成功"）
- ✅ 数据库有记录（`sylius_product_image` 表）
- ❌ 前台访问图片返回 404

**排查步骤**:

```bash
# 步骤 1: 检查数据库记录
docker compose exec mysql mysql -uroot -pmysql -e \
    "SELECT id, path, type FROM sylius_prod.sylius_product_image LIMIT 5;"
# 输出示例:
# +----+--------------------------------+------+
# | id | path                           | type |
# +----+--------------------------------+------+
# |  1 | ab/cd/ef1234567890abcdef.webp | main |
# +----+--------------------------------+------+

# 步骤 2: 检查原始文件是否存在
docker compose exec app ls -la /app/public/media/image/ab/cd/
# 应该看到文件: ef1234567890abcdef.webp

# 步骤 3: 检查文件权限
docker compose exec app ls -la /app/public/media/image/ab/cd/ef1234567890abcdef.webp
# 应该是: -rw-rw-r-- www-data www-data

# 步骤 4: 手动测试图片访问（容器内）
docker compose exec app curl -I http://localhost/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef1234567890abcdef.webp
# 应该返回: HTTP/1.1 302 Found

# 步骤 5: 测试通过宿主机 Nginx
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef1234567890abcdef.webp
```

**常见原因与解决方案**:

| 原因 | 解决方案 |
|------|---------|
| 文件不存在 | 检查上传是否成功，查看 Symfony 日志 |
| 权限不足 | `chown -R www-data:www-data /app/public/media` |
| 路径错误 | 数据库路径与实际文件路径不一致，删除记录重新上传 |
| Nginx 配置错误 | 检查 `location ~* ^/media/` 块是否存在 |

**修复权限**:
```bash
docker compose exec app bash -c '
    chown -R www-data:www-data /app/public/media
    chmod -R 775 /app/public/media
'
```

#### 问题 2: 缩略图生成失败（返回 500 错误）

**症状**:
- ✅ 原始图片存在
- ❌ 访问 `/media/cache/resolve/...` 返回 500 Internal Server Error
- ❌ Symfony 日志报错

**排查步骤**:

```bash
# 步骤 1: 查看 Symfony 日志
docker compose exec app tail -100 /app/var/log/prod.log
# 查找错误信息，例如:
# "Unable to create image from /app/public/media/image/ab/cd/ef.webp"

# 步骤 2: 检查 GD 扩展是否安装
docker compose exec app php -m | grep gd
# 应该输出: gd

# 步骤 3: 检查 WebP 支持
docker compose exec app php -r "var_dump(function_exists('imagewebp'));"
# 应该输出: bool(true)

# 步骤 4: 检查图片文件是否损坏
docker compose exec app php -r "
\$img = @imagecreatefromwebp('/app/public/media/image/ab/cd/ef.webp');
if (\$img === false) {
    echo 'File is corrupted or not a valid WebP image\n';
} else {
    echo 'Image is valid\n';
    imagedestroy(\$img);
}
"

# 步骤 5: 手动测试生成缩略图
docker compose exec app bin/console liip:imagine:cache:resolve ab/cd/ef.webp \
    --filter=sylius_shop_product_thumbnail -vvv
```

**常见原因与解决方案**:

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `Call to undefined function imagewebp()` | GD 扩展未安装或未启用 WebP | 重新构建镜像 `docker compose build --no-cache` |
| `Unable to create image from ...` | 图片文件损坏 | 删除文件，重新上传 |
| `Memory limit exceeded` | 图片过大，内存不足 | 增加 `php.ini` 中的 `memory_limit` |
| `Permission denied` | 无法写入缓存目录 | 修复权限 `chmod 775 public/media/cache` |

**重新构建镜像（如果 GD 扩展有问题）**:
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

#### 问题 3: 宿主机 Nginx 反向代理后图片 404

**症状**:
- ✅ 直接访问容器正常：`http://127.0.0.1:8080/media/...` → 200 OK
- ❌ 通过宿主机 Nginx 访问：`http://172.17.3.80:8090/media/...` → 404 Not Found

**排查步骤**:

```bash
# 步骤 1: 测试容器内访问
curl -I http://127.0.0.1:8080/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp
# 应该返回: HTTP/1.1 302 Found

# 步骤 2: 测试宿主机 Nginx 转发
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp
# 如果返回 404，说明 Nginx 转发有问题

# 步骤 3: 检查宿主机 Nginx 配置
cat /etc/nginx/sites-enabled/sylius-ports.conf | grep -A 15 "location.*media"

# 步骤 4: 检查 Host 头
curl -v -H "Host: localhost" http://127.0.0.1:8080/media/cache/resolve/...
# 应该返回 302

curl -v -H "Host: 172.17.3.80:8090" http://127.0.0.1:8080/media/cache/resolve/...
# 如果返回 404，说明 Host 头不匹配

# 步骤 5: 查看 Nginx 日志
sudo tail -50 /var/log/nginx/sylius-frontend-error.log
```

**解决方案**:

确保宿主机 Nginx 配置正确：

```nginx
# 必须包含此配置块
location ~* ^/media/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host localhost;  # ← 必须是 localhost
    # ... 其他配置
}
```

**验证修复**:
```bash
# 重载 Nginx
sudo nginx -t
sudo systemctl reload nginx

# 测试访问
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp
# 应该返回: HTTP/1.1 302 Found
```

#### 问题 4: 图片重定向 URL 错误

**症状**:
- ✅ 访问 `/media/cache/resolve/...` 返回 302
- ❌ 重定向的 Location 头域名/端口错误

**示例**:
```bash
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp

# 错误的响应:
HTTP/1.1 302 Found
Location: http://localhost:8080/media/cache/sylius_shop_product_thumbnail/ab/cd/ef.webp
          ↑          ↑
    应该是服务器IP  应该是 8090
```

**排查步骤**:

```bash
# 步骤 1: 检查是否配置了 Trusted Proxies
docker compose exec app grep -r "TRUSTED_PROXIES" .env.local
# 如果没有输出，说明未配置

# 步骤 2: 检查 Symfony 配置
docker compose exec app bin/console debug:config framework | grep -A 5 trusted

# 步骤 3: 测试重定向 URL
curl -I -H "X-Forwarded-Host: 172.17.3.80" \
     -H "X-Forwarded-Port: 8090" \
     http://127.0.0.1:8080/media/cache/resolve/...
```

**解决方案**:

配置 Symfony Trusted Proxies:

```bash
# 方式 1: 编辑 .env.local
cat >> .env.local << 'EOF'

###> symfony/framework-bundle trusted proxies ###
TRUSTED_PROXIES=127.0.0.1,REMOTE_ADDR
TRUSTED_HOSTS='^(localhost|172\.17\.3\.80)$'
###< symfony/framework-bundle trusted proxies ###
EOF

# 方式 2: 编辑配置文件
cat >> config/packages/framework.yaml << 'EOF'
framework:
    trusted_proxies: '127.0.0.1,REMOTE_ADDR'
    trusted_headers:
        - 'x-forwarded-for'
        - 'x-forwarded-host'
        - 'x-forwarded-proto'
        - 'x-forwarded-port'
EOF

# 清空缓存并重启
docker compose exec app bin/console cache:clear --env=prod
docker compose restart app
```

**验证修复**:
```bash
curl -I http://172.17.3.80:8090/media/cache/resolve/sylius_shop_product_thumbnail/ab/cd/ef.webp

# 正确的响应:
HTTP/1.1 302 Found
Location: http://172.17.3.80:8090/media/cache/sylius_shop_product_thumbnail/ab/cd/ef.webp
          ↑                ↑
      ✅ 正确的服务器IP   ✅ 正确的端口号
```

---

### 📝 图片处理最佳实践

#### 1. 上传图片推荐规格

| 图片类型 | 推荐尺寸 | 最大文件大小 | 推荐格式 | 备注 |
|---------|---------|-------------|---------|------|
| 产品主图 | 2400x3200 px | 5 MB | JPEG/WebP | 高质量展示图 |
| 产品列表缩略图 | 600x800 px | 500 KB | WebP | 自动生成 |
| 产品小缩略图 | 300x400 px | 200 KB | WebP | 自动生成 |
| 分类横幅图 | 2400x600 px | 2 MB | JPEG/WebP | 宽屏展示 |
| 管理员头像 | 400x400 px | 200 KB | JPEG/PNG | 正方形头像 |

**上传限制配置**:
```nginx
# 宿主机 Nginx (nginx-configs/sylius-ports.conf)
client_max_body_size 20M;

# PHP 配置 (.docker/dev/php.ini)
upload_max_filesize = 20M
post_max_size = 20M
```

**修改上传限制**:
```bash
# 编辑 Nginx 配置
sudo nano /etc/nginx/sites-enabled/sylius-ports.conf
# 修改: client_max_body_size 50M;

# 重载 Nginx
sudo nginx -t
sudo systemctl reload nginx

# 编辑 PHP 配置（需要重新构建镜像）
nano .docker/dev/php.ini
# 修改:
# upload_max_filesize = 50M
# post_max_size = 50M

# 重新构建
docker compose down
docker compose build --no-cache
docker compose up -d
```

#### 2. 图片优化建议

**上传前优化**（推荐工具）:

| 工具 | 类型 | 用途 | 链接 |
|------|------|------|------|
| TinyPNG | 在线 | JPEG/PNG 压缩 | https://tinypng.com/ |
| Squoosh | 在线 | WebP/AVIF 转换 | https://squoosh.app/ |
| ImageMagick | 命令行 | 批量处理 | `apt install imagemagick` |
| Photoshop | 软件 | 专业编辑 | 导出时选择"存储为 Web 格式" |

**命令行批量优化**:
```bash
# 安装 ImageMagick
sudo apt install imagemagick

# JPEG 质量压缩（85% 质量）
convert input.jpg -quality 85 output.jpg

# 批量压缩 JPEG
for file in *.jpg; do
    convert "$file" -quality 85 "optimized_$file"
done

# 转换为 WebP（80% 质量）
convert input.jpg -quality 80 output.webp

# 批量转换为 WebP
for file in *.jpg; do
    convert "$file" -quality 80 "${file%.jpg}.webp"
done
```

**Sylius 自动优化**:
- ✅ 自动转换为 WebP 格式（配置文件中 `format: webp`）
- ✅ 自动质量压缩到 80%（`quality: 80`）
- ✅ 自动生成多种尺寸缩略图
- ✅ 自动裁剪到指定比例（`mode: outbound`）

#### 3. 生产环境优化检查清单

**部署前检查**:

- [ ] ✅ 确认 PHP GD 扩展启用 WebP 支持
  ```bash
  docker compose exec app php -r "var_dump(function_exists('imagewebp'));"
  ```

- [ ] ✅ 配置 Nginx 静态资源缓存
  ```nginx
  location ~* ^/build/ {
      expires 365d;
      add_header Cache-Control "public, immutable";
  }
  ```

- [ ] ✅ 设置合理的上传文件大小限制
  ```nginx
  client_max_body_size 20M;
  ```

- [ ] ✅ 配置 Symfony Trusted Proxies（反向代理环境）
  ```bash
  TRUSTED_PROXIES=127.0.0.1,REMOTE_ADDR
  ```

- [ ] ✅ 设置正确的文件权限
  ```bash
  chown -R www-data:www-data public/media
  chmod -R 775 public/media
  ```

- [ ] ✅ 配置宿主机 Nginx `/media/` 路径处理
  ```nginx
  location ~* ^/media/ {
      proxy_set_header Host localhost;
  }
  ```

**定期维护**:

- [ ] ✅ 监控磁盘空间使用
  ```bash
  du -sh /var/www/sylius/public/media/*
  ```

- [ ] ✅ 定期清理未使用的缓存（可选）
  ```bash
  find public/media/cache -type f -atime +60 -delete
  ```

- [ ] ✅ 备份原始图片目录
  ```bash
  tar -czf media-backup-$(date +%Y%m%d).tar.gz public/media/image/
  ```

- [ ] ✅ 检查图片访问日志
  ```bash
  sudo grep "/media/cache" /var/log/nginx/sylius-frontend-access.log | tail -50
  ```

#### 4. 监控与维护

**磁盘空间监控脚本**:

```bash
#!/bin/bash
# monitor-media-storage.sh

echo "=== Sylius 媒体文件存储监控 ==="
echo ""

# 原始图片大小
original_size=$(docker compose exec app du -sh /app/public/media/image 2>/dev/null | awk '{print $1}')
echo "原始图片: $original_size"

# 缓存大小
cache_size=$(docker compose exec app du -sh /app/public/media/cache 2>/dev/null | awk '{print $1}')
echo "缩略图缓存: $cache_size"

# 文件数量
image_count=$(docker compose exec app find /app/public/media/image -type f 2>/dev/null | wc -l)
cache_count=$(docker compose exec app find /app/public/media/cache -type f 2>/dev/null | wc -l)

echo ""
echo "文件数量:"
echo "  原始图片: $image_count"
echo "  缓存文件: $cache_count"

# 磁盘使用率
disk_usage=$(df -h /var/www/sylius | tail -1 | awk '{print $5}' | sed 's/%//')
echo ""
echo "磁盘使用率: $disk_usage%"

# 警告阈值
if [ "$disk_usage" -gt 80 ]; then
    echo "⚠️  警告: 磁盘使用率超过 80%，建议清理缓存！"
fi
```

**清理策略脚本**:

```bash
#!/bin/bash
# clean-image-cache.sh

echo "=== 清理 Sylius 图片缓存 ==="
echo ""

# 选项 1: 清理所有缓存
read -p "清理所有缓存? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker compose exec app bin/console liip:imagine:cache:remove
    echo "✅ 所有缓存已清理"
    exit 0
fi

# 选项 2: 清理超过 30 天的缓存
read -p "清理超过 30 天的缓存? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker compose exec app find /app/public/media/cache -type f -mtime +30 -delete
    echo "✅ 30 天前的缓存已清理"
    exit 0
fi

# 选项 3: 清理特定过滤器
echo "可用的过滤器:"
echo "  1) sylius_shop_product_large_thumbnail"
echo "  2) sylius_admin_product_thumbnail"
echo "  3) 所有商城过滤器"
read -p "选择要清理的过滤器 (1-3): " choice

case $choice in
    1)
        docker compose exec app bin/console liip:imagine:cache:remove --filter=sylius_shop_product_large_thumbnail
        ;;
    2)
        docker compose exec app bin/console liip:imagine:cache:remove --filter=sylius_admin_product_thumbnail
        ;;
    3)
        docker compose exec app bin/console liip:imagine:cache:remove --filter=sylius_shop_product_thumbnail
        docker compose exec app bin/console liip:imagine:cache:remove --filter=sylius_shop_product_small_thumbnail
        docker compose exec app bin/console liip:imagine:cache:remove --filter=sylius_shop_product_large_thumbnail
        ;;
    *)
        echo "取消操作"
        exit 0
        ;;
esac

echo "✅ 缓存清理完成"
```

**使用方法**:
```bash
# 保存脚本
chmod +x monitor-media-storage.sh clean-image-cache.sh

# 监控存储
./monitor-media-storage.sh

# 清理缓存
./clean-image-cache.sh

# 添加到 crontab（每周日凌晨 3 点执行）
crontab -e
# 添加: 0 3 * * 0 /var/www/sylius/clean-image-cache.sh
```

---

## 附录

### 开发环境 vs 生产环境对比

| 项目 | 开发环境 | 生产环境 |
|------|----------|----------|
| **配置文件** | `.env` (APP_ENV=dev) | `.env.local` (APP_ENV=prod) |
| **.env.local 文件** | **删除或不存在** ✅ | **必须创建** ✅ |
| **docker-compose.yml** | `APP_ENV: "dev"` | `APP_ENV: "prod"` |
| **调试模式** | `APP_DEBUG=1` | `APP_DEBUG=0` |
| **前端编译** | `yarn build` | `yarn encore production` |
| **缓存** | 自动刷新 | 需手动清理 |
| **数据库名** | `sylius_dev` | `sylius_prod` |
| **邮件服务** | Mailhog (测试) | 真实 SMTP |
| **错误显示** | 详细错误页面 | 简化错误页面 |
| **性能** | 较慢 (调试模式) | 优化后 |

**关键配置优先级（从高到低）：**
1. Docker 环境变量（docker-compose.yml 中的 `environment`）
2. `.env.local` 文件
3. `.env` 文件

**配置冲突检查清单：**

开发环境检查：
- [ ] `.env.local` 文件不存在或已删除
- [ ] `docker-compose.yml` 中 `APP_ENV: "dev"`
- [ ] `.env` 中 `APP_ENV=dev`

生产环境检查：
- [ ] `.env.local` 文件存在且 `APP_ENV=prod`
- [ ] `docker-compose.yml` 中 `APP_ENV: "prod"`
- [ ] `.env.local` 中 `APP_SECRET` 已修改为随机字符串
- [ ] `.env.local` 中 `APP_DEBUG=0`

### 官方文档链接

- 官方安装文档: https://docs.sylius.com/getting-started-with-sylius/sylius-ce-installation-with-docker
- 系统要求: https://docs.sylius.com/getting-started-with-sylius/before-you-begin
- GitHub 仓库: https://github.com/Sylius/Sylius
- Sylius 官网: https://sylius.com

---

**文档版本**: v1.2
**最后更新**: 2025-10-15
**适用版本**: Sylius 2.x
**更新内容**:
- ✅ 添加 MySQL 健康检查配置
- ✅ 明确开发/生产环境配置区别
- ✅ 添加配置冲突检查清单
- ✅ 添加图片上传与缩略图生成机制详解
- ✅ 添加 Nginx 反向代理性能优化方案（HTTP/1.1、Gzip、缓冲优化）
- ✅ 添加缓存目录权限问题排查与解决方案

 # 添加 GitHub 到信任列表
  ssh-keyscan github.com >> ~/.ssh/known_hosts
# 使用腾讯云镜像
  composer config -g repos.packagist composer https://mirrors.cloud.tencent.com/composer/

● Nginx 配置正常!现在执行性能优化:

  docker compose exec app rm -f /usr/local/etc/php/conf.d/docker-php-ext-blackfire.ini && \
  docker compose exec app composer dump-autoload --optimize --classmap-authoritative && \
  docker compose exec app rm -rf var/cache/prod/* && \
  docker compose exec app php bin/console cache:warmup --env=prod && \
  docker compose exec app chown -R www-data:www-data var/ && \
  docker compose restart app
