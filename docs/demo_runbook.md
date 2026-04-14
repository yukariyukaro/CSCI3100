# Demo 演示运行手册（Runbook）

## 快速开始（本地）

- 安装依赖并初始化数据库：
  - `bundle install`
  - `bin/rails db:prepare`
- 重建 demo 演示数据（推荐）：
  - `bin/rails demo:reset`
- 仅补齐 demo 数据（不做清理）：
  - `bin/rails demo:seed`

## 可用的 demo 任务

- `demo:seed`：补齐 demo 用户/商品/聊天/支付等演示数据（不清理现有数据）
- `demo:reset`：仅清理 demo 范围内的数据后重建演示数据
- `demo:restore_assets`：覆盖式恢复 demo 头像/商品图片等资源（会 purge 旧附件）
- `demo:reset_chat`：仅重置 demo 的会话与消息
- `demo:prepare_payment`：准备 demo 支付相关数据（pending + 异常支付记录）
- `demo:purge_unattached_blobs`：非生产环境清理未引用的 ActiveStorage blobs（`DRY_RUN=1` 可预览）

## 安全保护（重要）

- demo 相关任务在 `test` 环境会直接拒绝执行（避免污染测试数据）
- 在 `production` 环境执行带“破坏性”的 demo 任务（例如 `demo:reset`、`demo:restore_assets`、`demo:reset_chat`）需要：
  - `CONFIRM_PRODUCTION_DATA_DESTRUCTION='true'`
  - 任务会在执行前输出 `current_database=<...>`，便于二次确认目标库

## Demo 账号（默认）

- 卖家：`demo_seller@example.com` / `password123`
- 买家：`demo_buyer@example.com` / `password123`

## 演示路径建议

- 商品列表：`/`
- 聊天列表：`/conversations`
- 支付列表：`/payments`

## 演示数据包含内容

- 至少 1 个可预定（active）商品
- 至少 1 个已预定（pending）商品 + 进行中交易（in_progress）
- 至少 1 个已售出（sold）商品 + 已完成交易（completed）
- 1 组会话 + 消息（ActionCable 广播可用）
- 1 条 fake 支付（pending），可用于展示支付页面跳转
- 1 条异常支付记录（manual_intervention_required），可用于展示人工介入与卖家侧处理
- demo 用户头像与商品图片会尽量自动恢复：
  - 默认读取 `lib/assets/demo_avatar.png`、`lib/assets/demo_product.jpg`（允许用 base64 文本占位）
  - 若文件缺失或不可用，会使用内置的最小占位图进行 attach

## Heroku 部署（main 自动部署）

- 工作流：分支开发 → 发 PR → 合并到 `main` → GitHub Actions 自动部署到 Heroku
- Release Phase：部署时会自动执行 `bundle exec rails db:migrate db:seed`
- 若需要在 Heroku（production）使用 fake 支付（演示用途），需要在 Config Vars 中设置：
  - `ALLOW_FAKE_PAYMENT_PROVIDER=true`
  - （可选）`PAYMENT_PROVIDER=fake`
- demo 场景数据（聊天/交易/支付）建议通过任务生成：
  - 在 Heroku Dashboard → More → Run console 执行：`bin/rails demo:reset`

## 可选：清理 ActionCable Redis 前缀（谨慎）

- 仅在你确认需要“断开/清理旧的订阅与遗留键”时启用：
  - `DEMO_RESET_CLEAR_CABLE=1 bin/rails demo:reset`
- 行为约束：
  - 只会按 `config/cable.yml` 的 `channel_prefix` 做定向清理
  - 不会执行 `flushall`
- 完成后建议前端刷新页面或重新打开聊天页以触发重连
