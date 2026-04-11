# Schema vs Models 审计（Task 1）

本文件用于对照 `db/schema.rb` 与 `app/models/*`，识别“模型校验/关联”与“数据库约束/索引/外键”的不一致点，并给出迁移策略建议。

审计范围（按 Task 1 要求）：`users / products / transactions / payments / conversations / messages`。

## 总览结论

- 当前大多数业务链路表（transactions/payments/conversations/messages）在 DB 层已具备较强的 NOT NULL/索引/外键支撑，模型层主要补充业务规则（buyer != seller、amount 非负等）。
- `products` 是主要软肋：DB 允许 `seller_id/name/description/price` 为空，与业务逻辑（预订/聊天/支付）相冲突，容易产生“无主商品/无价商品”等脏数据。
- `users` 在模型层要求 `name/email` presence，但 DB 层仍允许 NULL；本次 Task 2 优先收敛 `products`，`users` 的 NOT NULL 收敛可在后续任务处理。

## 对照明细

### users

- DB（schema.rb）
  - `name`：NULL 允许
  - `email`：NULL 允许，且有唯一索引 `index_users_on_email`
  - `password_digest`：NULL 允许
- Model（User）
  - `validates :name, presence: true`
  - `validates :email, presence: true, uniqueness: { case_sensitive: false }`
  - `has_secure_password`（要求 `password_digest` 在业务上应存在）
- 差异与风险
  - DB 允许 NULL，但模型层拒绝；若通过脚本/迁移/手动 SQL 插入可产生“无法登录/无法展示”的用户脏数据。

### products

- DB（schema.rb）
  - `name`：NULL 允许
  - `description`：NULL 允许
  - `price`：NULL 允许，且未固化精度/标度（当前为 `decimal` 无 precision/scale）
  - `seller_id`：NULL 允许（有索引与外键，但可为 NULL）
  - `sale_status`：`default: 0` 且 `null: false`
- Model（Product）
  - `validates :name, presence: true`
  - `validates :description, presence: true`
  - `belongs_to :seller`（Task 2 后将变为必填）
  - 业务方法：`reserve_by`/`cancel_reservation_by`/`mark_sold_by` 强依赖 `seller_id` 存在
- 差异与风险
  - DB 允许无主商品/无名商品/无描述商品/无价商品，会导致：
    - 预订逻辑 `reservable_by?` 直接拒绝或产生异常路径
    - 聊天入口依赖 `@product.seller.present?`
    - 金额类展示/排序在 NULL 场景下行为不稳定
- 建议与迁移策略（Task 2 已落地）
  - 非生产环境：删除 `seller_id/name/description` 为 NULL 的产品（以及其关联 messages/conversations/transactions/payments）
  - 生产环境：发现上述 NULL 即 fail-fast，要求先修复数据再部署（避免静默制造逻辑脏数据）
  - `price`：先 backfill NULL 为 0，再用显式 `USING` cast 固化为 `decimal(10,2)`，最后加 `NOT NULL` 与默认值

### transactions

- DB（schema.rb）
  - `product_id/buyer_id/seller_id`：`null: false`，且均有外键
  - `status`：`default: 0` 且 `null: false`
  - 部分唯一索引：`idx_only_one_active_transaction_per_product`（`where: status = 1`）
- Model（Transaction）
  - `validate :buyer_and_seller_must_differ`
  - `before_update`：在 `status=completed` 时写入 `completed_at`
- 差异与风险
  - DB 与模型基本一致；业务规则（buyer != seller）仅在模型层，属于可接受的业务约束层差异。

### payments

- DB（schema.rb）
  - `amount`：`decimal(10,2) null: false`
  - `provider`：`null: false`
  - `provider_reference`：允许 NULL，但在 `(provider_reference IS NOT NULL)` 条件下有唯一索引
  - 外键：`transaction_id` 必填；`resolved_by_id` 可空
- Model（Payment）
  - `amount` 非负校验
  - `provider` presence
  - `provider_reference` 在 `provider` scope 下唯一（allow blank）
  - `callback_token` 在 provider=fake 时必须
- 差异与风险
  - DB 与模型核心一致；`callback_token` 规则属于业务层约束（DB 不适合强加）。

### conversations

- DB（schema.rb）
  - `product_id/buyer_id/seller_id`：`null: false`，外键齐全
  - 唯一索引：`product_id + buyer_id`（避免同一买家对同一商品重复开聊）
- Model（Conversation）
  - `validate :buyer_and_seller_must_differ`
- 差异与风险
  - DB 与模型基本一致；buyer != seller 属业务规则。

### messages

- DB（schema.rb）
  - `conversation_id/sender_id/content`：`null: false`，外键齐全
- Model（Message）
  - `validates :content, presence: true`
  - `after_create_commit` 广播到 ActionCable
- 差异与风险
  - DB 与模型一致；广播逻辑属于业务层。

