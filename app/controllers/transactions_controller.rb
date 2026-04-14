class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product

  def create
    if @product.reserve_by(current_user)
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product),
                  notice: t("transactions.reserve_success")
    else
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product),
                  alert: t("transactions.reserve_failed")
    end
  end

  def destroy
    if @product.cancel_reservation_by(current_user)
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product),
                  notice: t("transactions.cancel_success")
    else
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product),
                  alert: t("transactions.cancel_failed")
    end
  end

  def complete
    if @product.mark_sold_by(current_user)
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product),
                  notice: t("transactions.sold_success")
    else
      redirect_to community_product_path(community_slug: @product.community.slug, id: @product),
                  alert: t("transactions.sold_failed")
    end
  end

  private

  def set_product
    @product = current_community_scope(Product).find(params[:id])
  end
end
