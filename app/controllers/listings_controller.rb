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

  def destroy
    @product = find_user_product
    return head :not_found if @product.blank?
    return redirect_not_active unless @product.active?

    unlist_product
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

  def listings_path_for_current_community
    community_listings_path(community_slug: Current.community.slug)
  end

  def find_user_product
    current_user.products.find_by(id: params[:id], community_id: Current.community.id)
  end

  def redirect_not_active
    redirect_to listings_path_for_current_community, alert: t(".not_active")
  end

  def unlist_product
    if @product.update(sale_status: :offlined)
      redirect_to listings_path_for_current_community, notice: t(".success")
    else
      redirect_to listings_path_for_current_community, alert: t(".failed")
    end
  end
end
