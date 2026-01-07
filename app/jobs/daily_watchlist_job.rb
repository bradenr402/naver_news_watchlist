class DailyWatchlistJob < ApplicationJob
  queue_as :default

  RECIPIENT_EMAILS = [ "you@example.com", "another@example.com" ] # replace with desired emails
  RESULTS_PER_PAGE = 10
  MAX_PAGES = 5

  SORT_MAP = {
    relevance: 0,
    latest: 1,
    oldest: 2
  }

  PERIOD_MAP = {
    "all" => "all time", # default
    "1h"  => "1 hour",
    "2h"  => "2 hours",
    "3h"  => "3 hours",
    "4h"  => "4 hours",
    "5h"  => "5 hours",
    "6h"  => "6 hours",
    "1d"  => "1 day",
    "1w"  => "1 week",
    "1m"  => "1 month",
    "3m"  => "3 months",
    "6m"  => "6 months",
    "1y"  => "1 year"
  }.freeze

  WATCHLIST = [
    {
      # Industry trends
      query: "coffee",
      press_names: [
        "매일경제",   # Maeil Business Newspaper
        "한국경제",   # Korea Economic Daily
        "조선비즈",   # Chosun Biz
        "토큰포스트"  # TokenPost
      ], # filter by specific press sources
      max: Float::INFINITY, # set max to Float::INFINITY to allow unlimited results up to MAX_PAGES
      sort_by: SORT_MAP[:latest], # sort by latest news
      period: "from20251201to20260107" # custom date range
    },
    {
      # Topical news
      query: "Naver AI",
      press_names: [], # set press_names to `[]` to allow all press sources
      max: RESULTS_PER_PAGE # set max to RESULTS_PER_PAGE to fetch only the first page
    },
    {
      # Competitor monitoring
      query: "Kakao Enterprise",
      press_names: nil, # set press_names to `nil` to allow all press sources
      max: RESULTS_PER_PAGE * 2, # set max greater than RESULTS_PER_PAGE to fetch multiple pages
      sort_by: SORT_MAP[:latest],
      period: "1m",
      device: "tablet"
    },
    {
      # Technology updates
      query: "AI semiconductor",
      # omit press_names to allow all press sources
      # omit max to allow unlimited results up to MAX_PAGES
      sort_by: SORT_MAP[:latest],
      period: "3m"
    },
    {
      # Fresh breaking news with a shorter time frame
      query: "Generative AI",
      max: nil, # set max to `nil` to allow unlimited results up to MAX_PAGES
      sort_by: SORT_MAP[:latest],
      period: "3h",
      device: "mobile" # simulate mobile device results
    }
  ]

  def perform
    sections = sections_for_watchlist
    sections = empty_sections if sections.all? { |section| section[:items].empty? }

    post_digest sections
  rescue => error
    Rails.error.report(
      error,
      handled: false,
      severity: :error,
      context: {
        job: self.class.name,
        watchlist_queries: WATCHLIST.pluck(:query),
        recipients: RECIPIENT_EMAILS
       }
    )

    error_payload = {
      class: error.class.name,
      message: error.message,
      backtrace: error.backtrace
    }

    DailyDigestMailer.error_email(RECIPIENT_EMAILS, error_payload).deliver_later
    raise error
  end

  def sections_for_watchlist
    WATCHLIST.map { |item| build_section(item) }
  end

  private

  def build_section(item)
    {
      **item.without(:max),
      items: fetch_and_select(item)
    }
  end

  def empty_sections
    [
      {
        query: nil,
        items: []
      }
    ]
  end

  def fetch_and_select(item)
    seen = []
    selected = []

    limit = item[:max] || Float::INFINITY
    page = 1

    while selected.size < limit && page <= MAX_PAGES
      options = item.without(:max, :press_names).merge(page:)

      api_response = NaverNewsFetcher.call(**options)
      ensure_serpapi_success! api_response, options[:query], page

      results = api_response[:news_results].to_a
      break if results.empty?

      results.each do |result|
        break if selected.size >= limit

        link = result[:link].to_s
        next if link.blank? || link.in?(seen)

        seen << link

        press_name = result.dig(:news_info, :press_name).to_s
        next unless item[:press_names].blank? || press_name.in?(item[:press_names])

        selected << {
          position: result[:position].to_i + (page - 1) * RESULTS_PER_PAGE,
          title: result[:title].to_s,
          snippet: result[:snippet].to_s,
          link:,
          news_date: result.dig(:news_info, :news_date).to_s,
          press_name:,
          press_link: result.dig(:news_info, :press_link).to_s
        }.compact
      end

      page += 1
    end

    selected
  end

  def ensure_serpapi_success!(api_response, query, page)
    status = api_response.dig(:search_metadata, :status)
    return if status == "Success"

    error_message = api_response[:error] || "Unknown SerpApi error"
    error = StandardError.new(
      "SerpApi Naver search failed (query=#{query.inspect}, page=#{page}): " \
      "status=#{status || 'unknown'} error=#{error_message}"
    )

    Rails.error.report(
      error,
      handled: false,
      severity: :error,
      context: {
        source: "SerpApi:NaverNews",
        query:,
        page:,
        serpapi_status: status,
        serpapi_error_message: error_message
      }
    )

    raise error
  end

  def post_digest(sections)
    DailyDigestMailer.digest_email(RECIPIENT_EMAILS, sections).deliver_later
  end
end
