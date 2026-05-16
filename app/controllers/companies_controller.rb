class CompaniesController < ApplicationController
  before_action :require_admin

  def index
    @companies = Company.order(:symbol)
  end

  def create
    symbol = params.dig(:company, :symbol)&.strip&.upcase

    if symbol.blank?
      redirect_to admin_path, alert: "Symbol is required."
      return
    end

    existing = Company.find_by(symbol: symbol)
    if existing
      if existing.picked?
        redirect_to admin_path, alert: "#{symbol} already picked."
        return
      end
      existing.picked!
      redirect_to admin_path, notice: "#{existing.name || symbol} is now picked."
      return
    end

    service = FmpService.new
    profile = service.fetch_profile(symbol)

    unless profile
      redirect_to admin_path, alert: "Could not find profile for #{symbol}."
      return
    end

    company = Company.upsert_from_profile(profile)
    import_news(service, company)

    redirect_to admin_path, notice: "Added #{company.name || company.symbol}."
  end

  def update
    @company = Company.find(params[:id])
    if @company.update(company_params)
      redirect_to admin_path, notice: "Company updated."
    else
      redirect_to admin_path, alert: @company.errors.full_messages.join(", ")
    end
  end

  def toggle_pick
    @company = Company.find(params[:id])
    @company.picked? ? @company.draft! : @company.picked!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@company) }
      format.html { redirect_to admin_path }
    end
  end

  def sync_news
    @company = Company.find(params[:id])
    service = FmpService.new
    count = import_news(service, @company)

    redirect_to admin_path, notice: "Synced #{count} news item(s) for #{@company.symbol}."
  end

  def destroy
    @company = Company.find(params[:id])
    @company.block!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@company) }
      format.html { redirect_to admin_path, notice: "#{@company.symbol} blocked." }
    end
  end

  private

  def import_news(service, company)
    items = service.fetch_news(company.symbol, limit: 10) || []
    items.each { |data| NewsItem.upsert_from_fmp(company, data) }
    items.size
  end

  def company_params
    params.require(:company).permit(:symbol, :name, :description)
  end

  def require_admin
    unless session[:admin]
      redirect_to admin_login_path, alert: "Please log in."
    end
  end
end
