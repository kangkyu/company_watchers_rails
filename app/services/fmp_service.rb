require "net/http"
require "json"
require "digest"

class FmpService
  BASE_URL = "https://financialmodelingprep.com/stable"

  def initialize
    @api_key = ENV.fetch("FMP_API_KEY")
  end

  def fetch_profile(symbol)
    data = get("profile", symbol: symbol.upcase)
    item = Array(data).first
    return nil unless item.is_a?(Hash)

    parse_profile(item)
  end

  def search_companies(query, limit: 10)
    data = get("search-symbol", query: query, limit: limit)
    data = get("search-name", query: query, limit: limit) if Array(data).empty?
    Array(data).filter_map do |item|
      next unless item.is_a?(Hash)

      {
        symbol: item["symbol"],
        name: item["name"],
        exchange: item["exchange"],
        currency: item["currency"]
      }
    end
  end

  # Note: per-symbol news is a paid endpoint on FMP as of Aug 2025.
  # Returns [] on free tier; kept so the sync flow is a graceful no-op
  # until the account is upgraded.
  def fetch_news(symbol, limit: 10)
    data = get("news/stock", symbols: symbol.upcase, limit: limit)
    return [] unless data.is_a?(Array)

    data.map { |item| parse_news_item(item) }
  end

  private

  def parse_profile(item)
    {
      symbol: item["symbol"],
      name: item["companyName"],
      sector: item["sector"],
      industry: item["industry"],
      ceo: item["ceo"],
      country: item["country"],
      website: item["website"],
      image: item["image"],
      description: item["description"],
      market_cap: format_market_cap(item["marketCap"])
    }
  end

  def parse_news_item(item)
    url = item["url"]
    {
      external_id: Digest::SHA1.hexdigest(url.to_s),
      url: url,
      title: item["title"],
      image: item["image"],
      source: item["publisher"],
      site: item["site"],
      snippet: item["text"],
      published_at: parse_time(item["publishedDate"])
    }
  end

  def format_market_cap(value)
    return nil unless value

    n = value.to_f
    if n >= 1_000_000_000_000
      "#{(n / 1_000_000_000_000).round(2)}T"
    elsif n >= 1_000_000_000
      "#{(n / 1_000_000_000).round(2)}B"
    elsif n >= 1_000_000
      "#{(n / 1_000_000).round(2)}M"
    else
      n.to_i.to_s
    end
  end

  def parse_time(str)
    return nil if str.blank?

    Time.parse(str)
  rescue ArgumentError
    nil
  end

  def get(endpoint, params = {})
    uri = URI("#{BASE_URL}/#{endpoint}")
    uri.query = URI.encode_www_form(params.merge(apikey: @api_key))
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    body = response.body.to_s
    return nil if body.start_with?("Restricted Endpoint", "Query Error")

    parsed = JSON.parse(body)
    return nil if parsed.is_a?(Hash) && (parsed["Error Message"] || parsed["error"])

    parsed
  rescue JSON::ParserError
    nil
  end
end
