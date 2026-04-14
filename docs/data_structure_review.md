# 数据结构审阅（Schema & Domain Model）

本文基于当前 `db/schema.rb`（Schema version: 2026_04_11_121000）与核心模型（`User/Product/Transaction/Payment/Conversation/Message`）梳理项目的数据结构、约束、索引与关键一致性规则，供演示与后续迭代参考。

## 1. 全局概览

### 核心业务链路

- 用户（users）发布商品（products）
- 买家预订商品后产生交易（transactions），并可产生支付（payments）
- 买家可针对商品与卖家建立会话（conversations），并发送消息（messages）
- 资源上传使用 ActiveStorage（active_storage_*）

### ER（文字版）

- users 1—N products（seller）
- products 1—N transactions
- transactions 1—N payments
- products 1—N conversations
- conversations 1—N messages
- users 1—N messages（sender）
- users 1—N conversations（buyer / seller）

## 2. 表结构与约束

以下均来自 `db/schema.rb`。

### 2.1 users

- 字段
  - `name` string（DB 允许 NULL）
  - `email` string（DB 允许 NULL）
  - `password_digest` string（DB 允许 NULL）
  - `created_at/updated_at`
- 索引
  - `index_users_on_email`：`email` 唯一索引
- 外键
  - 无（其他表引用 users）
- 模型层补充（`User`）
  - `has_secure_password`
  - `name/email` presence + `email` uniqueness（case_insensitive 通过 normalize 实现）
  - `has_one_attached :avatar`

结论：users 的“必填性”主要在模型层保证；数据库层仍允许 NULL，理论上可被手工 SQL/脚本写入脏数据（后续可选择迁移收紧）。

### 2.2 products

- 字段
  - `name` string NOT NULL
  - `description` text NOT NULL
  - `price` decimal(10,2) NOT NULL DEFAULT 0
  - `condition` string（可空）
  - `seller_id` bigint NOT NULL（外键 users）
  - `sale_status` int NOT NULL DEFAULT 0
  - AI 摘要相关：`ai_summary` text（可空）、`ai_summary_status` string DEFAULT "pending"、`ai_summary_requested_at` datetime
  - `created_at/updated_at`
- 索引
  - `index_products_on_seller_id`
- 外键
  - `products.seller_id -> users.id`
- 枚举/状态（模型 `Product`）
  - `sale_status`: `active(0) / pending(1) / sold(2)`

结论：products 已具备较强 DB 级硬约束（NOT NULL + 金额精度 + 默认值），能显著降低“无主商品/无价商品”导致的演示与测试不稳定。

### 2.3 transactions

- 字段
  - `product_id/buyer_id/seller_id` bigint NOT NULL
  - `status` int NOT NULL DEFAULT 0
  - `completed_at` datetime（可空）
  - `created_at/updated_at`
- 索引
  - `idx_only_one_active_transaction_per_product`：`product_id` 唯一（部分索引，where `status = 1`）
  - `index_transactions_on_product_id`
  - `index_transactions_on_buyer_id`、`index_transactions_on_seller_id`
  - `index_transactions_on_buyer_id_and_created_at`、`index_transactions_on_seller_id_and_created_at`
- 外键
  - `transactions.product_id -> products.id`
  - `transactions.buyer_id -> users.id`
  - `transactions.seller_id -> users.id`
- 枚举/状态（模型 `Transaction`）
  - `status`: `pending(0) / in_progress(1) / completed(2) / reviewed(3) / cancelled(4) / expired(5)`
- 一致性规则（模型层）
  - `buyer_id != seller_id`
  - `status` 变更为 `completed` 时自动写入 `completed_at`

结论：部分唯一索引保证“同一商品最多一个 in_progress 交易”，是预订/并发正确性的核心护栏。

### 2.4 payments

- 字段
  - `transaction_id` bigint NOT NULL
  - `amount` decimal(10,2) NOT NULL
  - `status` int NOT NULL DEFAULT 0
  - `provider` string NOT NULL
  - `provider_reference` string（可空）
  - `callback_token` string（可空）
  - `error_details` text（可空）
  - `resolved_at` datetime（可空）
  - `resolved_by_id` bigint（可空，外键 users）
  - `created_at/updated_at`
- 索引
  - `index_payments_on_provider_and_provider_reference`：(`provider`, `provider_reference`) 唯一（条件：`provider_reference IS NOT NULL`）
  - `index_payments_on_transaction_id`
  - `index_payments_on_status`
  - `index_payments_on_resolved_by_id`
- 外键
  - `payments.transaction_id -> transactions.id`
  - `payments.resolved_by_id -> users.id`
- 枚举/状态（模型 `Payment`）
  - `status`: `pending/succeeded/failed/cancelled/manual_intervention_required`
- 一致性规则（模型层）
  - `amount >= 0`
  - `provider` presence
  - `provider_reference` 按 provider 去重（允许空）
  - provider 为 fake 时要求 `callback_token` 存在

结论：amount 精度已固化为 decimal(10,2)，provider_reference 的条件唯一索引能避免重复回调/重复入账类问题。

### 2.5 conversations

- 字段
  - `product_id/buyer_id/seller_id` bigint NOT NULL
  - `created_at/updated_at`
- 索引
  - `index_conversations_on_product_id_and_buyer_id`：唯一（防重复开聊）
  - `index_conversations_on_product_id`
  - `index_conversations_on_buyer_id`
  - `index_conversations_on_seller_id`
- 外键
  - `conversations.product_id -> products.id`
  - `conversations.buyer_id -> users.id`
  - `conversations.seller_id -> users.id`
- 一致性规则（模型层）
  - `buyer_id != seller_id`

备注：为了保证“全新数据库从 0 跑迁移”稳定，产品外键的添加拆分为后置迁移（先建字段，再 add_foreign_key）。

### 2.6 messages

- 字段
  - `conversation_id` bigint NOT NULL
  - `sender_id` bigint NOT NULL
  - `content` text NOT NULL
  - `created_at/updated_at`
- 索引
  - `index_messages_on_conversation_id`
  - `index_messages_on_sender_id`
- 外键
  - `messages.conversation_id -> conversations.id`
  - `messages.sender_id -> users.id`
- 模型层补充
  - `after_create_commit` 通过 ActionCable 广播消息事件（实时聊天）

### 2.7 ActiveStorage（文件/图片）

- `active_storage_blobs / active_storage_attachments / active_storage_variant_records`
- attachment 唯一性索引：同一 record + name + blob 唯一（避免重复 attach）

当前项目中：
- `User`：`avatar`（带 thumb variant）
- `Product`：`image`（带 thumb variant）

## 3. 关键一致性与并发策略（业务视角）

### 3.1 预订与交易（Product ↔ Transaction）

- 目标：同一商品在任意时刻最多存在一个 `in_progress` 交易
- 数据库级护栏：`transactions(product_id)` 的部分唯一索引（where `status = 1`）
- 业务实现：`Product#reserve_by` 使用 `with_lock`，并在锁内：
  - `active?` 且无 `active_transaction` 才允许
  - 将 `sale_status` 更新为 `pending`
  - 创建 `transactions.status = in_progress`

### 3.2 支付与对账（Transaction ↔ Payment）

- 金额字段均为 `decimal(10,2)`（避免浮点误差）
- `provider_reference` 条件唯一索引支持幂等回调/避免重复引用

### 3.3 聊天会话（Product ↔ Conversation ↔ Message）

- 会话唯一性：同一买家对同一商品最多一个 conversation（DB 唯一索引）
- 消息写入后广播：`Message.after_create_commit` 广播到 `conversation_<id>` channel

## 4. 搜索能力与数据库依赖

- PostgreSQL：启用 `pg_trgm`，并在 Product 上使用 pg_search（tsearch + trigram）支持 typo tolerance 与中英文混合搜索。
- 非 PostgreSQL：`ProductSearch` 提供降级的 LIKE 搜索与简易 suggest（保证测试/本地环境可用）。

## 5. 风险点与改进建议（后续）

- users 表 DB 层允许 NULL（name/email/password_digest），建议后续通过迁移收紧到 NOT NULL，并评估历史数据修复策略。
- email 的“真正 case-insensitive 唯一性”在 DB 层目前依赖应用 normalize；若要更强保证，可考虑：
  - PostgreSQL 使用 CITEXT 或对 `LOWER(email)` 建唯一索引（需迁移与数据清洗）。
- 删除策略：当前多个关联设置 `dependent: :destroy`，对 demo/reset 的大规模清理要谨慎（避免 ActiveStorage 碎片与回调开销）。演示任务已提供受控清理与资源恢复入口，但未来可进一步规范“只在 demo scope 操作”的边界与审计日志。

---

参考：
- Schema：[db/schema.rb](file:///C:/Users/sunny/Desktop/CSCI3100/Project/CSCI3100/db/schema.rb)
- Model 审计基线（历史记录）：[schema_model_audit.md](file:///C:/Users/sunny/Desktop/CSCI3100/Project/CSCI3100/docs/schema_model_audit.md)

