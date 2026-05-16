# Company Watchers

Rails 8 app that tracks public-company profiles via the [Financial Modeling Prep](https://site.financialmodelingprep.com/) API. Modeled after `coffee_watchers_rails`.

## Stack
Rails 8.1, PostgreSQL, Tailwind, Importmap, Turbo, Stimulus.

## Setup

```bash
bin/rails db:create db:migrate
FMP_API_KEY=your_key ADMIN_PASSWORD=your_password bin/dev
```

Then visit http://localhost:3000.

## Env vars

| Var | Required | Default | Notes |
|-----|----------|---------|-------|
| `FMP_API_KEY` | yes | — | https://site.financialmodelingprep.com/developer/docs |
| `ADMIN_PASSWORD` | no | `company123` | Session-based admin login |

## Models

- `Company` — `symbol` (unique, uppercased), name, sector, industry, ceo, country, website, image, description, market_cap, status enum (draft/picked/blocked).
- `NewsItem` — `belongs_to :company`, external_id (unique sha1 of url), url, title, image, source, site, snippet, published_at.

## FMP endpoints used

Service: `app/services/fmp_service.rb`, base `https://financialmodelingprep.com/stable`.

| Method | Endpoint | Free tier? |
|--------|----------|-----------|
| `fetch_profile(symbol)` | `/profile?symbol=` | yes |
| `search_companies(query)` | `/search-symbol` then `/search-name` fallback | yes |
| `fetch_news(symbol)` | `/news/stock?symbols=` | **paid** — returns `[]` on free tier |

Per-symbol news is restricted on FMP free accounts since Aug 2025. The sync flow is a graceful no-op until the account is upgraded.

## Admin

- `/admin/login` — password from `ADMIN_PASSWORD`
- `/admin` — dashboard: add by ticker, search & import, sync all, picked list with per-company sync/unpick/remove

## Routes

- `GET /` → news feed (public, filters by search/symbol)
- `GET/POST/PATCH/DELETE /companies` + member `toggle_pick`, `sync_news`
- `DELETE /news_items/:id` (admin only)
- `namespace :admin` — dashboard, sessions, `sync_all`, `search_and_import`
