class NewsItem < ApplicationRecord
  belongs_to :company

  validates :external_id, presence: true, uniqueness: true
  validates :title, presence: true

  scope :ordered, -> { order(published_at: :desc) }
  scope :search, ->(query) {
    where("title ILIKE :q OR EXISTS (SELECT 1 FROM companies WHERE companies.id = news_items.company_id AND (companies.symbol ILIKE :q OR companies.name ILIKE :q))", q: "%#{query}%")
  }

  def self.upsert_from_fmp(company, data)
    item = company.news_items.find_or_initialize_by(external_id: data[:external_id])
    item.update!(
      url: data[:url],
      title: data[:title],
      image: data[:image],
      source: data[:source],
      site: data[:site],
      snippet: data[:snippet],
      published_at: data[:published_at]
    )
    item
  end

  def time_ago
    return "" unless published_at

    seconds = (Time.current - published_at).to_i
    case seconds
    when 0..59 then "just now"
    when 60..3599 then "#{seconds / 60}m ago"
    when 3600..86_399 then "#{seconds / 3600}h ago"
    when 86_400..2_591_999 then "#{seconds / 86_400}d ago"
    when 2_592_000..31_535_999 then "#{seconds / 2_592_000}mo ago"
    else "#{seconds / 31_536_000}y ago"
    end
  end
end
