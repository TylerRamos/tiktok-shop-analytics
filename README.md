# TikTok Shop Product Analytics Pipeline

**Trial Task Submission** - A production-ready Rails application that ingests TikTok Shop Seller Center Product Analytics data as daily snapshots and exposes it via a RESTful API with filtering capabilities.

---

## 🚀 Quick Start (Evaluator Guide)

```bash
# 1. Install dependencies
bundle install && npm install

# 2. Setup database
rails db:create db:migrate

# 3. Start the server
rails server
# → Server runs at http://localhost:3000

# 4. Test the sync (edit script/test_sync.rb with your TikTok credentials first)
ruby script/test_sync.rb

# 5. Query the API
curl "http://localhost:3000/api/v1/tik_tok_shops/1/product_analytics?start_date=2025-12-23&end_date=2025-12-25"
```

---

## 📋 Table of Contents

- [Quick Start](#quick-start-evaluator-guide)
- [Overview](#overview)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Database Schema](#database-schema)
- [Network Request Details](#network-request-details)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This application implements an end-to-end data pipeline following the Growi engineering pattern:

**discover → fetch → store → query → expose**

### Features

✅ **Daily Snapshot Storage** - Product metrics stored per day (idempotent)  
✅ **Backfill Support** - Sync historical data for any date range  
✅ **Pagination Handling** - Automatically fetches all pages  
✅ **Idempotent Sync** - Safe to re-run without duplicates  
✅ **RESTful API** - Query products with date range and GMV filters  
✅ **Production Logging** - Comprehensive logging for debugging  
✅ **Error Handling** - Exponential backoff retry logic  

---

## 🏗️ Architecture

```
┌─────────────────┐
│  TikTok Shop    │
│  Seller Center  │
└────────┬────────┘
         │ HTTPS (X-Bogus, X-Gnarly signed)
         ▼
┌─────────────────────────────────────┐
│  Node.js Fetcher (products-raw.mjs) │
│  - Signs requests with X-Bogus      │
│  - Handles pagination               │
│  - Returns JSON response            │
└────────┬────────────────────────────┘
         │ stdin/stdout
         ▼
┌─────────────────────────────────────┐
│  Rails Service (SyncProductAnalytics)│
│  - Loops through date range         │
│  - Upserts products                 │
│  - Creates daily snapshots          │
└────────┬────────────────────────────┘
         │ ActiveRecord
         ▼
┌─────────────────────────────────────┐
│  PostgreSQL/SQLite Database         │
│  - tik_tok_shop_products            │
│  - tik_tok_shop_product_snapshots   │
└────────┬────────────────────────────┘
         │ Query Service
         ▼
┌─────────────────────────────────────┐
│  API Endpoint                       │
│  GET /api/v1/tik_tok_shops/:id/     │
│      product_analytics              │
└─────────────────────────────────────┘
```

### Component Separation

| Component | Responsibility | Location |
|-----------|---------------|----------|
| **Fetcher** | Network requests, signing | `app/javascript/products-raw.mjs` |
| **Service Bridge** | Ruby ↔ Node.js | `app/services/sign_params_service.rb` |
| **Ingestion** | Data upserts, backfill | `app/services/tik_tok_shop/sync_product_analytics.rb` |
| **Worker** | Background jobs, retry | `app/jobs/sync_product_analytics_job.rb` |
| **Query** | Data aggregation | `app/services/tik_tok_shop/product_analytics_query.rb` |
| **API** | HTTP interface | `app/controllers/api/v1/tik_tok_shops_controller.rb` |

---

## 📦 Requirements

- **Ruby**: 3.2+ (see `.ruby-version`)
- **Rails**: 8.1+
- **Node.js**: 18+ (for encryption/signing)
- **Database**: PostgreSQL (production) or SQLite (development)
- **npm packages**: axios

---

## 🚀 Installation

### 1. Install Dependencies

```bash
# Navigate to project directory
cd tiktok-clean

# Install Ruby gems
bundle install

# Install Node.js dependencies
npm install
```

### 2. Database Setup

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Verify schema
rails db:schema:load
```

### 3. Verify Installation

```bash
# Check Ruby version
ruby -v  # Should be 3.2+

# Check Node version
node -v  # Should be 18+

# Check Rails
rails -v  # Should be 8.1+

# Verify encryption modules exist
ls app/javascript/encryption/
# Should show: xbogus.mjs, xgnarly.mjs
```

---

## ⚙️ Configuration

### Environment Variables (Optional)

For production, you can use environment variables instead of hardcoding credentials:

```bash
# .env (not committed to git)
TIKTOK_COOKIE="your_cookie_here"
TIKTOK_OEC_SELLER_ID="7496020242935155064"
TIKTOK_FP="verify_mgtck5di_g1D3MIo1_jzhg_4B1L_AWG5_v0hAcN4BqwS3"
```

### Credentials Required

To sync data, you need:

1. **Cookie** - TikTok Shop session cookie (from browser)
2. **OEC Seller ID** - Your TikTok Shop seller ID
3. **FP** - Fingerprint token (from browser)

**How to get credentials:**

1. Log in to [TikTok Shop Seller Center](https://seller-us.tiktok.com)
2. Open Chrome DevTools → Network tab
3. Navigate to Product Analytics page
4. Find any API request and copy:
   - Cookie header value
   - `oec_seller_id` from URL params
   - `fp` from URL params

---

## 💻 Usage

### Running a Sync Job

#### Option 1: Rails Console

```ruby
# Start Rails console
rails console

# Run sync for a single day
SyncProductAnalyticsJob.perform_now(
  tik_tok_shop_id: 1,
  start_date: "2025-12-23",
  end_date: "2025-12-23",
  cookie: "your_cookie_here",
  oec_seller_id: "7496020242935155064",
  fp: "verify_mgtck5di_..."
)

# Backfill last 30 days
SyncProductAnalyticsJob.perform_now(
  tik_tok_shop_id: 1,
  start_date: 30.days.ago.to_date.to_s,
  end_date: Date.today.to_s,
  cookie: "your_cookie_here",
  oec_seller_id: "7496020242935155064",
  fp: "verify_mgtck5di_..."
)
```

#### Option 2: Test Script

```bash
# Edit script/test_sync.rb with your credentials
ruby script/test_sync.rb
```

### Starting the Rails Server

```bash
# Development
rails server

# Production
RAILS_ENV=production rails server -p 3000
```

Server runs at: `http://localhost:3000`

---

## 📡 API Documentation

### Endpoint

```
GET /api/v1/tik_tok_shops/:id/product_analytics
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | TikTok Shop ID |
| `start_date` | string | Yes | Start date (YYYY-MM-DD) |
| `end_date` | string | Yes | End date (YYYY-MM-DD) |
| `min_gmv` | float | No | Minimum GMV filter (dollars) |

### Example Requests

#### 1. Basic Query (All Products)

```bash
curl "http://localhost:3000/api/v1/tik_tok_shops/1/product_analytics?start_date=2025-12-23&end_date=2025-12-25"
```

#### 2. Filter by GMV (Products with > $1000)

```bash
curl "http://localhost:3000/api/v1/tik_tok_shops/1/product_analytics?start_date=2025-12-23&end_date=2025-12-25&min_gmv=1000"
```

#### 3. Postman Collection

```json
{
  "method": "GET",
  "url": "http://localhost:3000/api/v1/tik_tok_shops/1/product_analytics",
  "params": {
    "start_date": "2025-12-23",
    "end_date": "2025-12-25",
    "min_gmv": "500"
  }
}
```

### Response Format

```json
{
  "data": [
    {
      "external_id": "7123456789",
      "title": "Wireless Bluetooth Headphones",
      "status": 1,
      "image_url": "https://p16-oec-ttp.tiktokcdn-us.com/...",
      "gmv": 2450.50,
      "items_sold": 88,
      "orders_count": 70
    },
    {
      "external_id": "7987654321",
      "title": "Smart Watch Pro",
      "status": 1,
      "image_url": "https://p16-oec-ttp.tiktokcdn-us.com/...",
      "gmv": 1820.00,
      "items_sold": 45,
      "orders_count": 42
    }
  ]
}
```

### Error Responses

#### Invalid Date Range
```json
{
  "error": "end_date must be after start_date"
}
```
**Status**: `400 Bad Request`

#### Missing Required Parameters
```json
{
  "error": "start_date and end_date are required"
}
```
**Status**: `400 Bad Request`

#### Invalid Date Format
```json
{
  "error": "Invalid date format. Use YYYY-MM-DD"
}
```
**Status**: `400 Bad Request`

---

## 🗄️ Database Schema

### `tik_tok_shop_products`

Stores product identity and static attributes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY | Auto-increment ID |
| `tik_tok_shop_id` | bigint | NOT NULL | Shop identifier |
| `external_id` | string | NOT NULL | TikTok product ID |
| `title` | string | | Product name |
| `image_url` | string | | Product image URL |
| `status` | integer | | Product status (1=live) |
| `stock` | integer | | Current stock count |
| `created_at` | datetime | | Record creation |
| `updated_at` | datetime | | Last update |

**Indexes:**
- `UNIQUE (tik_tok_shop_id, external_id)` - Prevents duplicates
- `INDEX (tik_tok_shop_id)` - Fast lookups by shop

### `tik_tok_shop_product_snapshots`

Stores daily product metrics (one row per product per day).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY | Auto-increment ID |
| `tik_tok_shop_id` | bigint | NOT NULL | Shop identifier |
| `tik_tok_shop_product_id` | bigint | NOT NULL, FK | Product reference |
| `snapshot_date` | date | NOT NULL | Snapshot date |
| `gmv` | decimal(10,2) | | Gross Merchandise Value |
| `items_sold` | integer | | Units sold |
| `orders_count` | integer | | Number of orders |
| `created_at` | datetime | | Record creation |
| `updated_at` | datetime | | Last update |

**Indexes:**
- `UNIQUE (tik_tok_shop_product_id, snapshot_date)` - One snapshot per product per day
- `INDEX (tik_tok_shop_id)` - Fast shop queries
- `INDEX (snapshot_date)` - Fast date range queries

---

## 🔍 Network Request Details

### Discovered Endpoint

```
POST https://seller-us.tiktok.com/api/v2/insights/seller/ttp/product/list/v2
```

### Query Parameters (Required)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `locale` | `en` | Localization |
| `language` | `en` | Language |
| `oec_seller_id` | `<seller_id>` | Seller identifier |
| `aid` | `4068` | App ID |
| `app_name` | `i18n_ecom_shop` | Application name |
| `fp` | `<fingerprint>` | Browser fingerprint |
| `device_platform` | `web` | Platform type |
| `X-Bogus` | `<generated>` | Anti-bot signature |
| `X-Gnarly` | `<generated>` | Request signature |

### Request Payload

```json
{
  "request": {
    "time_descriptor": {
      "start": "2025-12-23",
      "end": "2025-12-24",
      "timezone_offset": -28800
    },
    "ccr_available_date": "2025-12-23",
    "search": {
      "voc_statuses": [],
      "gmv_ranges": []
    },
    "filter": {},
    "list_control": {
      "rules": [{ "direction": 2, "field": "gmv" }],
      "pagination": { "size": 50, "page": 0 }
    }
  }
}
```

### Response Structure

```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "meta": {
          "product_id": "7123456789",
          "product_name": "Product Title",
          "product_image": "https://...",
          "product_status": 1,
          "inventory_cnt": 100
        },
        "stats": {
          "gmv": { "amount": 2450.50 },
          "unit_sold_cnt": 88,
          "order_cnt": 70
        }
      }
    ],
    "list_control": {
      "next_pagination": {
        "has_more": true,
        "page": 1
      }
    }
  }
}
```

### Authentication

Requires valid TikTok Shop session cookie in request headers.

### Special Tokens

- **X-Bogus**: Generated via `xbogus.mjs` - anti-scraping signature
- **X-Gnarly**: Generated via `xgnarly.mjs` - request verification

Both tokens are dynamically generated for each request using the encryption modules.

---

## 🛠️ Development

### Project Structure

```
app/
├── controllers/
│   └── api/v1/
│       └── tik_tok_shops_controller.rb    # API endpoint
├── jobs/
│   └── sync_product_analytics_job.rb      # Background worker
├── javascript/
│   ├── encryption/
│   │   ├── xbogus.mjs                     # X-Bogus signing
│   │   └── xgnarly.mjs                    # X-Gnarly signing
│   ├── products-raw.mjs                   # Raw API caller
│   └── products.mjs                       # stdin handler
├── models/
│   ├── tik_tok_shop_product.rb            # Product model
│   └── tik_tok_shop_product_snapshot.rb   # Snapshot model
└── services/
    ├── sign_params_service.rb             # Ruby ↔ Node bridge
    └── tik_tok_shop/
        ├── sync_product_analytics.rb      # Ingestion service
        └── product_analytics_query.rb     # Query service

db/
└── migrate/
    ├── *_create_tik_tok_shop_products.rb
    └── *_create_tik_tok_shop_product_snapshots.rb

config/
└── routes.rb                              # API routes

script/
└── test_sync.rb                           # Manual test script
```

### Running Tests

```bash
# Run all tests
rails test

# Run specific test
rails test test/services/tik_tok_shop/sync_product_analytics_test.rb
```

### Checking Logs

```bash
# Development logs
tail -f log/development.log

# Production logs
tail -f log/production.log

# Filter for sync logs
tail -f log/development.log | grep "TikTok Sync"
```

### Log Output Example

```
[TikTok Sync] Starting sync for shop 1 from 2025-12-23 to 2025-12-25
[TikTok Sync] Synced page 0 for 2025-12-23: 50 items
[TikTok Sync] Synced page 1 for 2025-12-23: 32 items
[TikTok Sync] Completed 2025-12-23: 82 items synced across 2 page(s)
[TikTok Sync] No items found for 2025-12-24
[TikTok Sync] Completed 2025-12-24: 0 items synced across 1 page(s)
[TikTok Sync] Completed sync for shop 1. Total items: 82
```

---

## 🐛 Troubleshooting

### Issue: "Node request failed"

**Cause**: Node.js not installed or wrong version

**Solution**:
```bash
node -v  # Check version (need 18+)
npm install  # Reinstall dependencies
```

### Issue: API returns code != 0

**Cause**: Cookie expired or invalid credentials

**Solution**:
1. Get fresh cookie from browser (expires ~24 hours)
2. Update credentials in sync call
3. Check logs for specific error code

### Issue: No items synced

**Possible causes**:
- Date has no data (normal) ✓
- Cookie expired
- Wrong seller ID
- API temporarily down

**Check logs**:
```bash
tail -f log/development.log | grep "TikTok Sync"
```

### Issue: Duplicate key error

**Cause**: Attempting to create duplicate snapshot

**Solution**: This shouldn't happen due to unique constraints. Check:
```ruby
# Verify unique constraint exists
rails db
> \d tik_tok_shop_product_snapshots
```

### Issue: Pagination incomplete

**Cause**: `has_more` logic error or API timeout

**Solution**:
- Check logs for page count
- Re-run sync (idempotent)
- Reduce `page_size` if timing out

---

## 📊 Performance Considerations

### Query Optimization

- Indexes on `(tik_tok_shop_id, snapshot_date)` ensure fast range queries
- Aggregation happens in database (not application layer)
- Use `EXPLAIN ANALYZE` for slow queries

### Backfill Strategy

```ruby
# Bad: Sync 365 days at once
SyncProductAnalyticsJob.perform_now(
  start_date: 365.days.ago,
  end_date: Date.today,
  ...
)

# Good: Chunk into smaller jobs
(0..12).each do |month_offset|
  SyncProductAnalyticsJob.perform_later(
    start_date: (month_offset + 1).months.ago.beginning_of_month,
    end_date: month_offset.months.ago.end_of_month,
    ...
  )
end
```

### Rate Limiting

TikTok may rate limit requests. Consider:
- Adding delays between pages
- Queueing jobs with delays
- Monitoring for HTTP 429 responses

---

## 📝 Known Limitations

- **Cookie Expiration**: Session cookies expire ~24 hours, requires manual refresh
- **Timezone**: Currently hardcoded to PST (-28800)

---
📄 Trial Task Notes

This is a **trial task submission** demonstrating:

✅ **Clean Architecture** - Fetcher → Ingestion → Query → API separation  
✅ **Daily Snapshots** - One row per product per day with unique constraints  
✅ **Idempotent Sync** - Safe to re-run without duplicates  
✅ **Backfill Support** - Syncs date ranges with pagination  
✅ **Production Ready** - Logging, error handling, retry logic  
✅ **Complete Documentation** - Setup, usage, API examples, troubleshooting  

### Evaluation Checklist

- ✅ Network request discovered and documented (see [Network Request Details](#network-request-details))
- ✅ Node.js fetcher with X-Bogus/X-Gnarly signing
- ✅ Rails migrations with proper indexes and unique constraints
- ✅ Service layer with clean separation of concerns
- ✅ Background worker with exponential backoff retry
- ✅ Query service with date range and GMV filtering
- ✅ RESTful API endpoint ready for Postman testing