# CSCI3100 Marketplace - Project Baseline

> **注意：** 本项目环境经过严格对齐（Ruby 3.3.8 / Rails 7.1.3）。任何私自更换版本或在 Windows 原生环境下运行的行为，都将视为对项目稳定性的破坏。

## 1. 开发环境要求 (Hard Requirements)

为了确保“在我的电脑上能跑，在助教电脑上报错”的情况不再发生，所有人必须使用以下技术栈：

| 组件         | 版本 / 要求                    | 备注                                       |
| ------------ | ------------------------------ | ------------------------------------------ |
| **操作系统** | **Linux (WSL2 Ubuntu 22.04+)** | **严禁直接在 Windows 原生环境运行**        |
| **Ruby**     | **3.3.8**                      | 必须通过 `rbenv` 或 `rvm` 安装             |
| **Rails**    | **7.1.3**                      | Web 框架基准                               |
| **Database** | **PostgreSQL**                 | 严禁使用 SQLite，确保生产环境一致性        |
| **Git 签名** | **@link.cuhk.edu.hk**          | 使用教育邮箱，便于通过审计                 |
| **Node.js**  | **v18+**                       | 必须安装，用于处理 Rails 资源编译 (Assets) |

> **补充安装指令 (nvm 方式):**
>
> ```bash
> curl -o- [https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh](https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh) | bash
> source ~/.bashrc
> nvm install 18
> ```

---

## 2. 快速开始 (Environment Setup)

如果你是第一次加入项目，请在你的 **WSL2 终端** 依次执行以下指令：

### 2.1 依赖安装

```bash
# 确保系统有 PostgreSQL 客户端开发库
sudo apt update
sudo apt install libpq-dev

# 验证 Ruby 版本
ruby -v # 必须输出 ruby 3.3.8

```

### 2.2 项目初始化

```bash
# 启动 PostgreSQL 数据库服务
sudo service postgresql start

# 创建数据库超级用户：
# Rails 默认使用你的 Linux 用户名连接数据库。执行以下命令创建一个同名的超级用户 (Superuser)：
# 如果提示 role already exists，请忽略并继续
sudo -u postgres createuser -s $(whoami)

# 克隆仓库并进入目录：
git clone https://github.com/yukariyukaro/CSCI3100.git
cd CSCI3100

# 锁定依赖版本：
# 执行安装，确保本地 Gem 树与 Gemfile.lock 完全一致。
bundle install

# Rails 数据库自动化配置 (Rails DB Prepare)
# 这一步会根据 config/database.yml 自动创建数据库并加载表结构 (Schema)。
rails db:prepare

```

---

### 常见初始化故障排除 (Troubleshooting)

| 报错信息 (Error Message)               | 根本原因 (Root Cause)                | 解决方案 (Solution)                                            |
| -------------------------------------- | ------------------------------------ | -------------------------------------------------------------- |
| `role "..." does not exist`            | 尚未执行 `createuser` 或用户名不匹配 | 重新执行 `sudo -u postgres createuser -s $(whoami)`            |
| `Is the server running locally?`       | PostgreSQL 服务未启动                | 执行 `sudo service postgresql start`                           |
| `Gem::Ext::BuildError (pg / nokogiri)` | 缺少 Linux 端的系统依赖库            | 执行 `sudo apt install libpq-dev build-essential`              |
| `database "..." already exists`        | 之前初始化过，残留了旧数据库         | 运行 `bundle exec rails db:drop db:create db:migrate` 强行重置 |

---

### 2.3 启动开发服务器

```bash
rails server -b 0.0.0.0

```

访问 `localhost:3000` 看到 "Hello World" 即表示环境配置成功。

---

## 3. 敏捷协作流程 (Agile Workflow)

我们采用 **Feature Branching (GitHub Flow)** 模式。严禁任何人直接向 `main` 分支提交代码。

### 3.1 任务开发步骤

1. **拉取最新代码：** `git checkout main && git pull`
2. **创建功能分支：** `git checkout -b feature/your-task-name`
3. **本地开发与测试：** 开发完成后，确保 `bundle exec rspec` (如果已配置) 全部通过。
4. **发起 Pull Request (PR)：** 将分支推送到 GitHub 后，在网页端发起 PR。
5. **代码评审：** 至少需要一名其他队员 Review 并 Approve 后，方可合并至 `main`。

### 3.2 Commit 命名规范

请务必使用有意义的描述：

- `feat: ...` (新功能)
- `fix: ...` (修复 Bug)
- `docs: ...` (修改文档)
- `test: ...` (增加测试)

---

## 4. 强制红线 (Team Rules)

1. **禁止强制推送：** 严禁对 `main` 分支使用 `git push -f`。
2. **保持数据库 Schema 同步：** 如果你修改了数据库（执行了 `rails generate migration`），必须第一时间提醒其他队员执行 `rails db:migrate`。
3. **Gemfile 锁死：** 严禁私自修改 `Gemfile` 中的版本号。如果需要增加新的 Gem，必须先在群里沟通。

---

## 5. 生产环境 (Production)

- **Public URL:** [https://cuhk-marketplace-csci3100-6b82f95ad3ac.herokuapp.com/](https://cuhk-marketplace-csci3100-6b82f95ad3ac.herokuapp.com/)
- **部署负责人：** Tan Yihao (sty0000)

---

### PS

如果你在配置过程中遇到关于 `pg` 或 `nokogiri` 的安装错误，99% 的原因是因为你没有在 **WSL2** 环境下运行。

---

## 6. 环境的退出与恢复 (Exiting and Re-entering)

为了避免端口占用和环境变量失效，请严格遵守以下操作规范：

### 6.1 退出开发环境 (Exiting)

- **停止 Rails 服务：** 在运行 `rails s` 的终端按下 `Ctrl + C`。
  - **警告：** 严禁直接关闭终端窗口。如果不按 `Ctrl + C` 退出，后台进程会锁定 `3000` 端口并留下 `server.pid` 文件，导致下次启动失败。
- **退出 WSL 终端：** 输入 `exit` 或直接关闭窗口。

### 6.2 重新进入环境 (Re-entering)

1. **定位项目：** 重新打开终端后，必须首先进入项目目录：

   ```bash
   cd ~/cuhk_marketplace
   ```

2. **恢复环境变量 (Critical)：** 由于 `export` 命令在关闭窗口后会失效，若需执行 Heroku 部署，必须重新注入 API Key。
   - **永久方案（推荐）：** 执行以下命令将 Key 写入你的系统配置，此后无需重复输入：

     ```bash
     echo 'export HEROKU_API_KEY="你的_HEROKU_API_KEY"' >> ~/.bashrc
     source ~/.bashrc
     ```

### 6.3 故障排除 (Troubleshooting)

如果启动服务器时提示 `A server is already running`，请手动删除残留的 PID 文件：

```bash
rm -f tmp/pids/server.pid
```

### 7. Git 协作与仓库管理规范 (Git Workflow Spec)

为了确保代码质量与提交记录的可追溯性，所有人必须严格遵守 **"Sync -> Branch -> Code -> Pull Request"** 的闭环流程。

### 7.1 标准开发循环 (The Golden Loop)

任何功能的修改必须遵循以下 6 个步骤，**禁止在 `main` 分支直接修改代码**。

1. **同步主线 (Sync Main):** 确保你的本地 `main` 是最新的。

```bash
git checkout main
git pull origin main

```

2. **创建功能分支 (Create Branch):** 以 `main` 为基准创建新分支。

```bash
git checkout -b <branch-name>

```

1. **本地修改 (Local Modification):** 进行代码编写。
2. **本地测试 (Local Test):** **严禁提交无法运行的代码。** 必须在本地运行 `rails s` 验证功能。
3. **提交更改 (Commit):** 遵循命名规范（见下文）。

```bash
git add .
git commit -m "feat: add user login logic"

```

1. **推送远程 (Push & PR):** 将分支推送到 GitHub，并在网页端发起 **Pull Request (PR)**。

```bash
git push origin <branch-name>

```

---

### 7.2 分支命名规范 (Branch Naming)

分支名必须具有语义化，格式为 `类型/简短描述`：

| 命名格式       | 适用场景               | 示例                     |
| -------------- | ---------------------- | ------------------------ |
| `feat/xxx`     | 开发新功能             | `feat/product-search`    |
| `fix/xxx`      | 修复现有 Bug           | `fix/db-connection-leak` |
| `docs/xxx`     | 仅修改文档/README      | `docs/update-workflow`   |
| `refactor/xxx` | 代码重构（不改变功能） | `refactor/user-model`    |

---

### 7.3 提交信息规范 (Commit Message)

助教会通过 Commit 审计你的工作量。**严禁使用 "update", "fix", "111" 等无意义的描述。**
推荐格式：`<type>: <description>`

- **Bad:** `git commit -m "fixed"`
- **Good:** `git commit -m "fix: resolve nil pointer error in product controller"`

---

### 7.4 远程仓库合并协议 (Merging Protocol)

1. **禁止强推 (No Force Push):** 严禁对 `main` 分支使用 `git push -f`。
2. **代码评审 (Code Review):** 所有 PR 必须至少经过 **1 名其他队员** 的 Review 后方可合并。
3. **清理分支:** 合并完成后，必须删除远程和本地的功能分支，保持仓库整洁。

```bash
# 删除远程分支
git push origin --delete <branch-name>
# 删除本地分支
git branch -d <branch-name>

```

## 8. 安全与敏感信息 (Security Guidelines)

1. **环境变量：** 严禁将包含 `HEROKU_API_KEY` 或其他私密凭证的 `.env` 文件提交至仓库。
2. **Git 拦截：** 提交前请检查 `git status`，确保没有敏感配置文件进入暂存区。
3. **泄漏处理：** 若不慎将密钥推送到远端，必须立即在 Heroku Dashboard 重新生成（Regenerate）API Key，并通知负责人 (sty0000) 撤回相关 Commit。

## 9. 自动化审计 (Automated Guardrails)(暂未启用)

本项目已计划配置 **GitHub Actions (CI)**。任何试图合并至 `main` 的 PR 必须通过以下硬性检测：

- **Ruby 版本匹配 (3.3.8)**
- **RSpec 单元测试 100% 通过**
- **RuboCop 代码风格检查无报错**

**未通过 CI 检测的代码将无法合并，请务必在本地测试通过后再提交。**
