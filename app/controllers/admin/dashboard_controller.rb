class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    @companies = Company.picked.includes(:news_items).order(created_at: :desc)
    @company_count = Company.picked.count
    @news_count = NewsItem.count
  end

  private

  def require_admin
    unless session[:admin]
      redirect_to admin_login_path, alert: "Please log in."
    end
  end
end
