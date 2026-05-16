class Company < ApplicationRecord
  has_many :news_items, dependent: :destroy

  enum :status, { draft: 0, picked: 1, blocked: 2 }

  validates :symbol, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_symbol

  def self.upsert_from_profile(profile)
    company = find_or_initialize_by(symbol: profile[:symbol])
    company.assign_attributes(
      name: profile[:name],
      sector: profile[:sector],
      industry: profile[:industry],
      ceo: profile[:ceo],
      country: profile[:country],
      website: profile[:website],
      image: profile[:image],
      description: profile[:description],
      market_cap: profile[:market_cap]
    )
    company.status = :picked if company.new_record?
    company.save!
    company
  end

  def block!
    blocked!
    news_items.destroy_all
  end

  def fmp_url
    "https://financialmodelingprep.com/financial-statements/#{symbol}" if symbol.present?
  end

  private

  def normalize_symbol
    self.symbol = symbol.to_s.strip.upcase if symbol.present?
  end
end
