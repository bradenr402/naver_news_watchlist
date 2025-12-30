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
  }.with_indifferent_access.freeze

  WATCHLIST = [
    {
      # Industry trends
      query: "coffee",
      press_names: [
        "매일경제",   # Maeil Business Newspaper
        "한국경제",   # Korea Economic Daily
        "조선비즈"    # Chosun Biz
      ],
      max: 5,
      sort_by: SORT_MAP[:latest],
      period: "1w"
    },
    {
      # Company news
      query: "Naver AI",
      press_names: [], # allow all press sources
      max: 15 # uses pagination to get 2 pages
    },
    {
      # Competitor monitoring
      query: "Kakao Enterprise",
      press_names: [],
      max: 25,
      sort_by: SORT_MAP[:latest],
      period: "1m",
      device: "tablet"
    },
    {
      # Technology updates
      query: "AI semiconductor",
      press_names: [],
      max: 10,
      sort_by: SORT_MAP[:latest],
      period: "3m"
    },
    {
      # Fresh breaking news across AI ecosystem
      query: "Generative AI",
      press_names: [],
      max: 10,
      sort_by: SORT_MAP[:latest],
      period: "3h",
      device: "mobile"
    }
  ]

  def perform
    sections = WATCHLIST.map { |item| build_section(item) }
    sections = empty_sections if sections.all? { |section| section[:items].empty? }

    post_digest sections
  end

  private

  def build_section(item)
    {
      **item.except(:max),
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
    seen = {}
    selected = []

    limit = item[:max] || Float::INFINITY
    page = 1

    while selected.size < limit && page <= MAX_PAGES
      options = item.except(:max, :press_names)

      api = NaverNewsFetcher.new(**options).call(page:)
      results = api[:news_results].to_a

      break if results.empty?

      results.each do |result|
        break if selected.size >= limit

        link = result[:link].to_s
        next if link.empty? || seen[link]

        press_name = result.dig(:news_info, :press_name).to_s

        next unless item[:press_names].empty? || press_name.in?(item[:press_names])

        seen[link] = true

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

  def post_digest(sections)
    RECIPIENT_EMAILS.each { |email| DailyDigestMailer.digest_email(email, sections).deliver_later }
  end
end
