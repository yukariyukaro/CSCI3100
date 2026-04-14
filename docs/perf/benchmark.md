# Performance Benchmark

## Goal

- Validate that tenant-scoped index/search endpoints stay responsive under load.

## Prerequisites

- App running with production-like DB (Postgres) and Redis
- Seed data loaded for at least one community slug

## Suggested Benchmarks

- Products index: `GET /:community_slug/products`
- Autocomplete: `GET /:community_slug/products/autocomplete?query=ma`

## Example (wrk)

- `wrk -t4 -c50 -d30s http://localhost:3000/chung-chi/products`
- `wrk -t4 -c50 -d30s 'http://localhost:3000/chung-chi/products/autocomplete?query=ma'`

## What To Record

- p50/p95/p99 latency
- throughput (req/s)
- error rate

