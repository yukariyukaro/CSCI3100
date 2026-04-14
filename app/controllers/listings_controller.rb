class ListingsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def new
    @product = Product.new
  end

  def create
    @product = build_product
    return render_quota_exceeded if exceeds_quota?

    if @product.save
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product), notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def listing_params
    params.require(:product).permit(:name, :description, :price, :condition, :image)
  end

  def build_product
    product = Product.new(listing_params)
    product.seller = current_user
    product
  end

  def render_quota_exceeded
    @product.errors.add(:base, t("listings.errors.quota_exceeded"))
    render :new, status: :unprocessable_content
  end

  def exceeds_quota?
    limit = current_user.community.max_active_products_per_user
    current_user.products.where(community_id: current_user.community_id, sale_status: :active).count >= limit
  end
end
