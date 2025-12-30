class NaverNewsFetcher
  def initialize(query:, sort_by: 0, period: "1d", **options)
    @base_params = {
      engine: "naver",
      where: "news",
      query: query,
      sort_by: sort_by,
      period: period
    }.merge(options)
  end

  def call(page: 1)
    client = SerpApi::Client.new(api_key: serpapi_key)

    fetch_news(client, page:)
  end

  private

  def serpapi_key
    Rails.application.credentials.dig(:serpapi, :api_key)
  end

  def fetch_news(client, page:)
    client.search(**@base_params, page:)
  end
end
