# Sylius 部署文档

## 📋 目录

- [系统要求](#系统要求)
- [项目架构说明](#项目架构说明)
- [开发环境部署](#开发环境部署)
- [生产环境部署](#生产环境部署)
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

### 2. 配置生产环境变量

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

**文档版本**: v1.1
**最后更新**: 2025-10-14
**适用版本**: Sylius 2.x
**更新内容**:
- ✅ 添加 MySQL 健康检查配置
- ✅ 明确开发/生产环境配置区别
- ✅ 添加配置冲突检查清单
