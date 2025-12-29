class NaverNewsFetcher
  def initialize(query:, sort_by: 0, period: "1d", device: "desktop")
    @query = query
    @period = period
    @sort_by = sort_by
    @device = device
  end

  def call
    client = SerpApi::Client.new(api_key: serpapi_key)

    result = fetch_news client

    status = result.dig(:search_metadata, :status)
    return result if status == "Success"

    Rails.logger.error("[SerpApi:Naver] status=#{status || 'unknown'}. Returning empty payload.")
    empty_payload
  rescue => e
    Rails.logger.error "[SerpApi:Naver] Fetch failed: #{e.class} #{e.message}"
    empty_payload
  end

  private

  def serpapi_key
    Rails.application.credentials.dig(:serpapi, :api_key)
  end

  def fetch_news(client)
    client.search(
      engine: "naver",
      query: @query,
      where: "news",
      period: @period,
      sort_by: @sort_by,
      device: @device,
    )
  end

  def empty_payload
    { news_results: [] }
  end
end
