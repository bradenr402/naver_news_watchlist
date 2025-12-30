class NaverNewsFetcher
  def initialize(query:, **options)
    @base_params = {
      engine: "naver",
      where: "news",
      query:,
      sort_by: 0,
      period: "1d"
    }.merge(options)
  end

  def call(page: 1)
    client = SerpApi::Client.new(api_key: serpapi_key)

    fetch_news(client, page:)
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
        **@base_params.without(:engine, :where)
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
      search_metadata: {
        status: "Success"
      },
      news_results: []
    }
  end

  def fetch_news(client, page:)
    client.search(**@base_params, page:)
  end
end
