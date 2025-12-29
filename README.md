# Naver News Watchlist (Rails + SerpApi)

An API‑only Ruby on Rails app that monitors Naver News via SerpApi and sends a single daily digest email for a configurable set of queries.

This repository contains the **source code and reference implementation** used in the SerpApi blog post:

> **Building an API‑only Ruby on Rails Naver News Watchlist**  
> Blog post link (placeholder): https://example.com/blog/naver-news-watchlist

<!-- TODO: Update with actual link when published. -->

For a step‑by‑step tutorial, explanation of design choices, and extended code samples, **refer to the blog post**. This README focuses on how to run and adapt the code.

---

## Features

- Fetches Naver News results via SerpApi for a configurable watchlist of keywords
- Filters duplicates and (optionally) restricts to specific press names
- Paginates results to respect a per‑query max item count
- Groups items by query into digest sections
- Sends a UTF‑8 plain‑text daily email digest

---

## Architecture

- **API‑only Rails app** (no database, no HTML frontend)
- **Service object** for SerpApi calls:
  - `app/services/naver_news_fetcher.rb`
- **Job** that orchestrates fetching, filtering, and email delivery:
  - `app/jobs/daily_watchlist_job.rb`
- **Mailer + text template** that build the digest email:
  - `app/mailers/daily_digest_mailer.rb`
  - `app/views/daily_digest_mailer/digest_email.text.erb`
- No persistence; everything runs in memory and is delivered as an email

For a deeper walkthrough of each component, see the blog post.

---

## Requirements

- Ruby 4.0 (or the version specified in `.ruby-version`, if present)
- Rails 8
- Bundler 2+ (or 4+ if you are on Ruby 4)
- SerpApi account and API key
- SMTP account for sending email (e.g., Gmail or any SMTP provider)

---

## Setup

### 1. Clone the repo and install dependencies

```bash
git clone https://github.com/YOUR_ORG/naver_news_watchlist.git
cd naver_news_watchlist
bundle install
```

### 2. Configure SerpApi credentials

Add your SerpApi API key to Rails credentials:

```bash
bin/rails credentials:edit
```

```yaml
serpapi:
  api_key: YOUR_API_KEY
```

`NaverNewsFetcher` reads this via:

```ruby
Rails.application.credentials.dig(:serpapi, :api_key)
```

### 3. Configure SMTP credentials

Add SMTP credentials (Gmail or other provider) to Rails credentials:

```bash
bin/rails credentials:edit
```

```yaml
smtp:
  user_name: YOUR_SMTP_USERNAME
  password: YOUR_SMTP_PASSWORD
```

Then configure Action Mailer in `config/environments/production.rb` (and optionally `development.rb`). See the blog post for a detailed Gmail + `letter_opener` example.

---

## Watchlist Configuration

The watchlist lives in `app/jobs/daily_watchlist_job.rb` as a `WATCHLIST` constant.

Each entry supports:

- `query` (String, required): keyword(s) passed to SerpApi’s Naver engine
- `press_names` (Array of Strings): allowed outlet names (empty array allows all)
- `max` (Integer): maximum number of items to include for that query
- `sort_by` (Integer): mapped via `SORT_MAP` (`:relevance`, `:latest`, `:oldest`)
- `period` (String): time window key, mapped via `PERIOD_MAP` (e.g. `"1d"`, `"1w"`, `"3m"`)
- `device` (String, optional): `"desktop"`, `"mobile"`, or `"tablet"`

Customize, add, or remove entries to match your own news watchlist.

---

## Running the App

### 1. Test the fetcher in Rails console

```ruby
NaverNewsFetcher.new(query: "커피").call
```

You should see a hash containing a `:news_results` array from SerpApi.

### 2. Generate a digest manually

```ruby
job = DailyWatchlistJob.new
sections = DailyWatchlistJob::WATCHLIST.map { |item| job.send(:build_section, item) }
DailyDigestMailer.digest_email("you@example.com", sections).deliver_now
```

### 3. Run the full job

```ruby
DailyWatchlistJob.perform_now
```

In development (with `letter_opener` configured), the digest email will open in your browser.

---

## Scheduling the Daily Digest

This repo does not include a scheduler. Use whatever fits your environment, for example:

- Cron + the [`whenever`](https://github.com/javan/whenever) gem to enqueue `DailyWatchlistJob` daily
- Platform scheduler (Heroku Scheduler, Kubernetes CronJob, etc.) that runs:

```bash
bin/rails runner "DailyWatchlistJob.perform_later"
```

---

## Testing

To run the test suite:

```bash
bin/rails test
```

There are starter tests for the job and mailer under `test/jobs` and `test/mailers`.

---

## Links

- Read the full blog post (placeholder): https://example.com/blog/naver-news-watchlist
<!-- TODO: Update with actual link when published. -->
- Read the official SerpApi [Naver News Results documentation](https://serpapi.com/naver-news-results)
- Experiment with live queries in the [Naver News Results Playground](https://serpapi.com/playground?engine=naver&where=news)
- Report issues or request features on the SerpApi [Public Roadmap](https://github.com/serpapi/public-roadmap)
