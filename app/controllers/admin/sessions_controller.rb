class Admin::SessionsController < ApplicationController
  def new
  end

  def create
    if params[:password] == ENV.fetch("ADMIN_PASSWORD", "company123")
      session[:admin] = true
      redirect_to admin_path, notice: "Logged in."
    else
      flash.now[:alert] = "Invalid password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:admin)
    redirect_to root_path, notice: "Logged out."
  end
end
