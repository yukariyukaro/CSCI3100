class ListingsController < ApplicationController
  def index
  end

  def new
  end

  def create
    redirect_to listings_path
  end
end
