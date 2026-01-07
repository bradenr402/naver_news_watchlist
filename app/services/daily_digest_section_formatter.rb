class DailyDigestSectionFormatter
  include ActionView::Helpers::TextHelper

  INDENT_SIZE       = 2
  HEADER_SEPARATOR  = "\n\n".freeze
  ITEM_SEPARATOR    = "\n\n".freeze
  SECTION_SEPARATOR = "\n\n\n---\n\n\n".freeze
  CUSTOM_DATE_RANGE_REGEX = /\Afrom(\d{8})to(\d{8})\z/.freeze

  attr_reader :section, :items, :results_count

  def initialize(section)
    @section        = section
    @items          = section[:items] || []
    @results_count  = @items.size
  end

  def self.call(section)
    new(section).call
  end

  def call
    [ header, body ].join(HEADER_SEPARATOR)
  end

  def header
    [ section_title, section_details, header_punctuation ].join
  end

  def body
    items.map { item_body(_1) }.join(ITEM_SEPARATOR)
  end

  def item_body(item)
    lines = [
      [ "Date", item[:news_date] ],
      [ "Link", item[:link] ],
      [ "Source", item_source(item) ],
      [ "Snippet", item[:snippet] ]
    ].compact

    lines.map! do |label, value|
      next unless value

      "#{" " * INDENT_SIZE * 2}#{label}: #{value}"
    end

    title_line = "#{" " * INDENT_SIZE}#{item[:position]}) #{item[:title]}"
    lines.prepend(title_line).join("\n")
  end

  private

  def section_title
    "#{pluralize results_count, 'result'} for \"#{section[:query]}\""
  end

  def section_details
    meta = metadata.map { |key, value| "#{key.to_s.humanize}: #{value}" }
    meta.any? ? " (#{meta.join(", ")})" : ""
  end

  def header_punctuation
    results_count.zero? ? "." : ":"
  end

  def metadata
    {
      device: section.fetch(:device, "desktop"),
      sort: human_sort_by,
      period: human_period,
      filtered_by_press: section[:press_names]&.join(", ")
    }.compact
  end

  def human_sort_by
    sort_by = section[:sort_by] || NaverNewsFetcher::DEFAULT_PARAMS[:sort_by]

    key = DailyWatchlistJob::SORT_MAP.key(sort_by) || :relevance
    key.to_s.titleize
  end

  def human_period
    period = section[:period] || NaverNewsFetcher::DEFAULT_PARAMS[:period]

    return DailyWatchlistJob::PERIOD_MAP[period] if DailyWatchlistJob::PERIOD_MAP.key?(period)

    return "unknown period" unless (match = period.match(CUSTOM_DATE_RANGE_REGEX))

    from_date, to_date = match.captures.map(&:to_date)
    "from #{from_date} to #{to_date}"
  rescue Date::Error
    "unknown period"
  end

  def item_source(item)
    [ item[:press_name], item[:press_link]&.then { "(#{it})" } ].compact.join(" ")
  end
end
