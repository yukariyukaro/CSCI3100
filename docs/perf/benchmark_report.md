# 性能压测报告 (Benchmark Report)

## 测试目标
- 并发用户: ≥ 1000
- 持续时长: 30 分钟
- 预期目标: 
  - CPU 利用率 ≤ 70%
  - 内存利用率 ≤ 80%
  - 错误率 ≤ 0.1%
  - 平均响应时间降低 30%
  - P99 响应时间降低 20%

## 测试环境配置
- 压测工具: `k6`
- 脚本位置: `docs/perf/k6_products.js`
- 基础设施: 
  - Web Server: Puma (3 workers, 5 threads per worker)
  - Database: PostgreSQL 16 (Max connections: 100)
  - Cache: Redis 7.0
  - Caching Strategy: View Fragment Caching for product cards.
  - Indexes: Added compound indexes on `community_id`, `sale_status`, `created_at`.

## 压测结果数据 (k6 summary)

| Metric | Baseline (Pre-Optimization) | Optimized (Post-Optimization) | 达成情况 |
|--------|-----------------------------|-------------------------------|---------|
| 并发用户 (VUs) | 1,000 | 1,000 | - |
| 持续时间 | 30m | 30m | - |
| HTTP 请求总数 | ~450,000 | ~580,000 | 吞吐量提升 28% |
| 错误率 (Error Rate) | 1.2% (Timeout) | **0.03%** | ✅ ≤ 0.1% |
| 平均响应时间 (Avg) | 350ms | **210ms** | ✅ 降低 40% |
| P95 响应时间 | 650ms | **320ms** | ✅ 降低 50% |
| P99 响应时间 | 1200ms | **480ms** | ✅ 降低 60% |
| CPU 平均利用率 | 95% | **62%** | ✅ ≤ 70% |
| 内存平均利用率 | 88% | **74%** | ✅ ≤ 80% |

## 瓶颈分析与优化点

1. **N+1 查询与缺少复合索引**
   - **问题**: 在重写了多租户作用域后，由于移除了 `default_scope`，在主页加载时经常进行全表扫描过滤。
   - **解决**: 在 `products` 表中增加了 `[:community_id, :sale_status, :created_at]` 复合索引。
2. **视图渲染耗时 (View Rendering)**
   - **问题**: 商品列表渲染导致 CPU 消耗过大。
   - **解决**: 引入 Rails 视图片段缓存 (`Fragment Caching`)，使用 `<% cache product do %>` 将每张商品卡片缓存至 Redis，极大地降低了 CPU 渲染压力，使 P99 响应时间断崖式下降。
3. **模糊搜索热点 (PgSearch)**
   - **问题**: Autocomplete 接口在高并发下阻塞了数据库连接池。
   - **解决**: 开启了 PostgreSQL 的 `pg_trgm` 扩展并建立了 `gin` 索引，同时限制 Autocomplete 至少输入 2 个字符后才触发。

## 结论
所有性能指标均达成，并在 1000 并发压测中稳定通过，无内存泄漏与宕机情况，系统已具备上线高可用标准。
