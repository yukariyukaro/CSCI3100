class ListingsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create]
  before_action :set_listing, only: %i[show]

  def index
    @listings = Listing.includes(:user).order(created_at: :desc)
  end

  def show
    @escrow = @listing.escrow
  end

  def new
    @listing = current_user.listings.new
  end

  def create
    @listing = current_user.listings.new(listing_params)

    if @listing.save
      redirect_to listing_path(@listing), notice: "Listing created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def listing_params
    params.require(:listing).permit(:title, :description, :price)
  end
end
