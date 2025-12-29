class DailyWatchlistJob < ApplicationJob
  include ActionView::Helpers::TextHelper # For truncate method

  queue_as :default

  WATCHLIST = [
    {
      # Brand / product monitoring
      query: "Bonanza Coffee",
      press_names: [
        "매일경제",   # Maeil Business Newspaper
        "한국경제",   # Korea Economic Daily
        "조선비즈"    # Chosun Biz
      ],
      max: 10
    },
    {
      # Company / AI roadmap monitoring
      query: "Naver AI",
      press_names: [], # allow all press sources
      max: 5
    },
    {
      # Competitor monitoring
      query: "Kakao Enterprise",
      press_names: [],
      max: 10
    }
  ]

  # TODO: use pagination to fetch more than 10 results if needed

  def perform
    sections = WATCHLIST.map { |item| build_section(item) }

    sections = empty_sections if sections.all? { |section| section[:items].empty? }

    post_digest sections
  end

  private

  def build_section(item)
    {
      query: item[:query],
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
    api = NaverNewsFetcher.new(query: item[:query]).call
    results = api[:news_results].to_a

    seen = {}
    selected = []

    results.each do |result|
      break if selected.size >= item[:max]

      link = result[:link].to_s
      next if link.empty? || seen[link]

      press_name = result.dig(:news_info, :press_name).to_s

      next unless item[:press_names].empty? || press_name.in?(item[:press_names])

      seen[link] = true

      selected << {
        position: result[:position].to_i,
        title: result[:title].to_s,
        snippet: result[:snippet].to_s,
        link:,
        news_date: result.dig(:news_info, :news_date).to_s,
        press_name:,
        press_link: result.dig(:news_info, :press_link).to_s
      }.compact
    end

    selected
  end

  def post_digest(sections)
    recipient = "you@example.com" # replace with desired email
    DailyDigestMailer.digest_email(recipient, sections).deliver_later
  end
end
