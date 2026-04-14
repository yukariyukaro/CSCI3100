# Rollback Guide

## Scope

This app uses incremental migrations. Rolling back requires both code rollback and schema rollback.

## Safe Rollback Checklist

- Disable new deploys (freeze pipeline)
- Confirm current release health (`/up`)
- Snapshot database (logical dump or storage snapshot)
- Roll back application image/version
- If needed, roll back migrations with `rails db:rollback STEP=n` to a known good schema version
- Verify tenant routing works for at least one community slug
- Verify core flows: browse products, chat, reserve, pay (fake), profile update

## Notes on Tenant Migrations

- Community IDs are backfilled and enforced as NOT NULL on `users/products/conversations/transactions`.
- Removing multi-tenant requires code changes plus dropping these columns and tables; do not do this as a hotfix.

