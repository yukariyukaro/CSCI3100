# 数据字典 (Data Dictionary)

## 核心实体 (Core Entities)

### `communities` (社区/书院)
代表多租户架构中的一个隔离租户，例如中大的一所书院。
- `id` (PK): 唯一标识
- `name` (String): 书院全称 (例如: "Chung Chi College")
- `abbreviation` (String): 书院简称 (例如: "CC")
- `slug` (String): URL 友好的标识符 (例如: "chung-chi")
- `max_active_products_per_user` (Integer): 用户最大活跃商品数配额，默认 50。

### `users` (用户)
系统注册用户。
- `id` (PK): 唯一标识
- `name` (String): 用户名
- `email` (String): 邮箱地址 (唯一)
- `password_digest` (String): 加密密码
- `community_id` (FK): 用户当前所属社区

### `products` (商品)
用户发布的二手商品。
- `id` (PK): 唯一标识
- `name` (String): 商品名称
- `description` (Text): 商品详情
- `price` (Decimal): 价格
- `condition` (String): 物品状况 (e.g., 'new', 'used')
- `seller_id` (FK): 卖家 (关联 `users`)
- `community_id` (FK): 固化的社区归属 (关联 `communities`)
- `sale_status` (Integer): 售卖状态 (0=active, 1=pending, 2=sold, 3=offlined)
- `ai_summary` (Text): AI 生成的摘要
- `ai_summary_status` (String): 摘要状态 (pending, processing, completed, failed)

### `conversations` (对话)
买家与卖家针对某个商品的私信会话。
- `id` (PK): 唯一标识
- `product_id` (FK): 关联商品
- `buyer_id` (FK): 买家
- `seller_id` (FK): 卖家
- `community_id` (FK): 强制锚定于商品所在社区

### `messages` (消息)
会话中的具体消息。
- `id` (PK): 唯一标识
- `conversation_id` (FK): 关联会话
- `sender_id` (FK): 发送者
- `content` (Text): 消息内容

### `transactions` (交易)
商品预定与购买的交易记录。
- `id` (PK): 唯一标识
- `product_id` (FK): 关联商品
- `buyer_id` (FK): 买家
- `seller_id` (FK): 卖家
- `community_id` (FK): 强制锚定于商品所在社区
- `status` (Integer): 交易状态 (0=pending, 1=completed, 2=cancelled)

### `payments` (支付)
交易的支付记录 (集成 Stripe/Fake)。
- `id` (PK): 唯一标识
- `transaction_id` (FK): 关联交易
- `amount` (Decimal): 支付金额
- `status` (Integer): 状态 (0=pending, 1=completed, 2=failed, 3=refunded)
- `provider` (String): 支付提供商 ('stripe', 'fake')
- `provider_reference` (String): 第三方交易号

### `audit_events` (审计日志)
记录关键的安全和越权行为。
- `id` (PK): 唯一标识
- `community_id` (FK): 操作发生的社区
- `user_id` (FK): 操作用户
- `action` (String): 操作类型 (e.g., 'cross_tenant_write_blocked')
- `metadata` (JSON): 额外的请求信息 (IP, User-Agent, etc.)
