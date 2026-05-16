class Admin::SyncController < ApplicationController
  before_action :require_admin

  def sync_all
    service = FmpService.new
    results = []

    Company.picked.find_each do |company|
      next if company.symbol.blank?

      profile = service.fetch_profile(company.symbol)
      Company.upsert_from_profile(profile) if profile

      news = service.fetch_news(company.symbol, limit: 10) || []
      news.each { |data| NewsItem.upsert_from_fmp(company, data) }

      results << "#{company.symbol}: #{news.size} news"
    end

    redirect_to admin_path, notice: "Sync complete. #{results.join(', ')}"
  end

  def search_and_import
    query = params[:keyword].to_s.strip

    if query.blank?
      redirect_to admin_path, alert: "Please enter a company name or symbol."
      return
    end

    service = FmpService.new
    results = service.search_companies(query, limit: 10)

    if results.empty?
      redirect_to admin_path, alert: "No companies found for \"#{query}\"."
      return
    end

    imported = []
    skipped = 0

    results.each do |result|
      if Company.exists?(symbol: result[:symbol])
        skipped += 1
        next
      end

      profile = service.fetch_profile(result[:symbol])
      next unless profile

      company = Company.upsert_from_profile(profile)
      news = service.fetch_news(company.symbol, limit: 10) || []
      news.each { |data| NewsItem.upsert_from_fmp(company, data) }

      imported << company.symbol
    end

    parts = []
    parts << "Imported: #{imported.join(', ')}" if imported.any?
    parts << "#{skipped} already existed" if skipped > 0
    parts << "No new companies found" if imported.empty? && skipped == 0

    redirect_to admin_path, notice: parts.join(". ")
  end

  private

  def require_admin
    unless session[:admin]
      redirect_to admin_login_path, alert: "Please log in."
    end
  end
end
