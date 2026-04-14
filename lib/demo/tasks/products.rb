module Demo
  module Tasks
    module Products
      def self.ensure_all!(seller:)
        Demo::Tasks::PRODUCT_DEFINITIONS.transform_values do |attrs|
          product = Product.find_or_initialize_by(name: attrs.fetch(:name), seller_id: seller.id)
          product.assign_attributes(
            description: attrs.fetch(:description),
            price: attrs.fetch(:price),
            condition: attrs.fetch(:condition)
          )
          product.save! if product.changed?
          product
        end
      end

      def self.reset_statuses_to_active!
        Demo::Tasks::Scope.products_scope.find_each do |product|
          next if product.active?

          product.update!(sale_status: :active)
        end
      end
    end
  end
end
