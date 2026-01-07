class NaverNewsFetcher
  DEFAULT_PARAMS = {
    engine: "naver",
    where: "news",
    sort_by: DailyWatchlistJob::SORT_MAP[:relevance], # Relevance
    period: "1d" # 1 day
  }.freeze

  attr_reader :base_params

  def initialize(query:, **options)
    @base_params = DEFAULT_PARAMS.merge(options).merge(query:)
  end

  def self.call(page: 1, **args)
    new(**args).call(page:)
  end

  def call(page: 1)
    client = SerpApi::Client.new(api_key: serpapi_key)
    client.search(page:, **base_params)
  rescue => error
    # Ignore "no results" errors
    return empty_payload if error.message.include? "Naver hasn't returned any results for this query"

    Rails.error.report(
      error,
      handled: false,
      severity: :error,
      context: {
        source: self.class.name,
        page:,
        **base_params.without(:engine, :where)
      }.compact
    )
    raise error
  end

  private

  def serpapi_key
    Rails.application.credentials.dig(:serpapi, :api_key)
  end

  def empty_payload
    {
      search_metadata: { status: "Success" },
      news_results: []
    }
  end
end
