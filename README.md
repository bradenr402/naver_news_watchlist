# API‑only Ruby on Rails Naver News Watchlist

This repository contains the source code used in the SerpApi blog post [Building an API‑only Ruby on Rails Naver News Watchlist](https://example.com/blog/naver-news-watchlist). <!-- TODO: Update with actual link when published. -->

For a step‑by‑step tutorial, refer to the blog post. This README focuses on how to run and adapt the code.

---

## Architecture

- **API‑only Rails app** (no database, no HTML frontend)
- **Service object** for SerpApi calls:
  - [app/services/naver_news_fetcher.rb](app/services/naver_news_fetcher.rb)
- **Job** that orchestrates fetching, filtering, and email delivery:
  - [app/jobs/daily_watchlist_job.rb](app/jobs/daily_watchlist_job.rb)
- **Mailer + text template** that build the digest email:
  - [app/mailers/daily_digest_mailer.rb](app/mailers/daily_digest_mailer.rb)
  - [app/views/daily_digest_mailer/digest_email.text.erb](app/views/daily_digest_mailer/digest_email.text.erb)
- No persistence; everything runs in memory and is delivered as an email

For a deeper walkthrough of each component, see the [blog post](https://example.com/blog/naver-news-watchlist). <!-- TODO: Update with actual link when published. -->

---

## Requirements

- Ruby **4.0.0**
- Rails **8.1.1**
- Bundler **4.0.3**
- A **SerpApi** [account](https://serpapi.com/users/sign_up) and [API key](https://serpapi.com/manage-api-key)

---

## Setup

### 1. Clone the repo and install dependencies

```shell
git clone https://github.com/bradenr402/naver_news_watchlist.git
cd naver_news_watchlist
bundle install
```

### 2. Configure SerpApi credentials

Add your SerpApi API key to Rails credentials:

```shell
bin/rails credentials:edit
```

```yml
serpapi:
  api_key: YOUR_API_KEY
```

### 3. Configure SMTP credentials

Add SMTP credentials (Gmail or other provider) to Rails credentials:

```shell
bin/rails credentials:edit
```

```yml
smtp:
  user_name: YOUR_EMAIL@gmail.com
  password: YOUR_APP_PASSWORD
```

Then configure Action Mailer in `config/environments/production.rb` (and optionally `development.rb`).

---

## Email Delivery

- **Development**  
  Emails are opened in your browser via [`letter_opener`](https://github.com/ryanb/letter_opener) and are already configured in [`config/environments/development.rb`](config/environments/development.rb).

- **Production**  
  SMTP delivery is preconfigured in [`config/environments/production.rb`](config/environments/production.rb). After adding:

  ```yml
  smtp:
    user_name: YOUR_EMAIL@gmail.com
    password: YOUR_APP_PASSWORD
  ```

  to credentials, Rails will use Gmail’s SMTP server out of the box.

- **Sender + recipients**
  - The sender address is defined in [`ApplicationMailer`](app/mailers/application_mailer.rb) and uses `Rails.application.credentials.dig(:smtp, :user_name)`.
  - Digest recipients are controlled via the `RECIPIENT_EMAILS` constant in [`DailyWatchlistJob`](app/jobs/daily_watchlist_job.rb).

---

## Watchlist Configuration

The watchlist lives in `app/jobs/daily_watchlist_job.rb` as a `WATCHLIST` constant.

Each entry supports:

- `query` (String, required): keyword(s) passed to Naver
- `press_names` (Array of Strings): outlet names to filter results by (empty array = no filtering)
- `max` (Integer): maximum number of items to include for that query
- `sort_by` (Integer): mapped via `SORT_MAP` (`:relevance`, `:latest`, `:oldest`) in [`DailyWatchlistJob`](app/jobs/daily_watchlist_job.rb)
- `period` (String): time window key (e.g., `"1d"`, `"1w"`, `"3m"`, etc.), mapped via `PERIOD_MAP` in [`DailyWatchlistJob`](app/jobs/daily_watchlist_job.rb)
- `device` (String, optional): `"desktop"`, `"mobile"`, or `"tablet"` (passed through to SerpApi)

You can adjust `RESULTS_PER_PAGE`, `MAX_PAGES`, and `RECIPIENT_EMAILS` directly in [`DailyWatchlistJob`](app/jobs/daily_watchlist_job.rb) to control pagination and who receives the digest.

---

## Running the App

You can run the following commands in the Rails console to test each part of the system:

### 1. Fetch news results:

```ruby
results = NaverNewsFetcher.new(query: "coffee").call
news_results = results[:news_results]
```

### 2. Generate watchlist sections:

```ruby
sections = DailyWatchlistJob.new.sections_for_watchlist
```

### 3. Run the full job:

```ruby
DailyWatchlistJob.perform_now
```

In development—with `letter_opener` configured—the digest email will automatically open in your default browser.

---

## Scheduling the Daily Digest

This repo does not include a scheduler. Use whatever fits your environment, for example:

- Cron + the [`whenever`](https://github.com/javan/whenever) gem to enqueue `DailyWatchlistJob` daily
- Platform scheduler (Heroku Scheduler, Kubernetes CronJob, etc.) that runs:

  ```shell
  bin/rails runner "DailyWatchlistJob.perform_later"
  ```

---

## Testing

In production, you would typically write unit tests for the service object, job, and mailer. This repo does not include tests to keep the focus on the core implementation.

---

## Links

- Read the full blog post: [Building an API‑only Ruby on Rails Naver News Watchlist](https://example.com/blog/naver-news-watchlist) <!-- TODO: Update with actual link when published. -->
- Read the official SerpApi [Naver News Results documentation](https://serpapi.com/naver-news-results)
- Browse the official SerpApi [Ruby Library](https://github.com/serpapi/serpapi-ruby)
- Experiment with live queries in the [Naver News Results Playground](https://serpapi.com/playground?engine=naver&where=news)

---

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use, modify, and distribute the code.
