class NewsItemsController < ApplicationController
  def index
    @news_items = NewsItem.joins(:company).where(companies: { status: :picked }).includes(:company).ordered

    if params[:search].present?
      @news_items = @news_items.search(params[:search])
    end

    if params[:symbol].present?
      @news_items = @news_items.joins(:company).where(companies: { symbol: params[:symbol].upcase })
    end

    @total_items = NewsItem.joins(:company).where(companies: { status: :picked }).count
    @company_count = Company.picked.count
  end

  def destroy
    unless session[:admin]
      redirect_to root_path, alert: "Not authorized"
      return
    end

    NewsItem.find(params[:id]).destroy
    redirect_to root_path, notice: "News item deleted."
  end
end
