# Monitoring

## Health

- Liveness/health: `GET /up`

## Logs

- App logs: STDOUT (production config uses tagged logging with request_id)
- Important audit events: `audit_events` table (tenant boundary blocks and community changes)

## Key Signals

- HTTP: request rate, error rate (4xx/5xx), latency (p50/p95/p99)
- DB: connection saturation, slow queries (enable Postgres slow query log in production)
- Redis/Sidekiq: queue depth, job latency, retries
- Tenant security: count of `audit_events.action = tenant.forbidden_listing_write`

## Suggested Alerts

- 5xx rate > 1% for 5 minutes
- p99 latency > 200ms for 5 minutes
- Sidekiq queue latency > 60s
- Spike in `tenant.forbidden_listing_write` (potential probing)

