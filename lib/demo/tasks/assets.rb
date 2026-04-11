require "base64"
require "stringio"

module Demo
  module Tasks
    module Assets
      DEMO_AVATAR_PNG_B64 = <<~B64.delete("\n").freeze
        iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII=
      B64
      DEMO_PRODUCT_JPG_B64 = <<~B64.delete("\n").freeze
        /9j/4AAQSkZJRgABAQEASABIAAD/2wBDABALDA4MChAODQ4SEhQWGBYWGBwZHB0dHBwdHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHj/wAALCAABAAEBAREA/8QAFQABAQAAAAAAAAAAAAAAAAAAAAf/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAwT/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCZAAD/2Q==
      B64

      def self.ensure!
        ensure_user_avatars!
        ensure_product_images!
      end

      def self.restore!
        users_scope.find_each { |user| attach_avatar!(user, overwrite: true) }
        Demo::Tasks::Scope.products_scope.find_each { |product| attach_product_image!(product, overwrite: true) }
      end

      def self.users_scope
        User.where(email: Demo::Tasks::DEMO_EMAILS)
      end
      private_class_method :users_scope

      def self.attach_avatar!(user, overwrite:)
        user.avatar.purge if overwrite && user.avatar.attached?

        bytes = read_png_bytes_from_path_or_fallback(demo_avatar_path, fallback_b64: DEMO_AVATAR_PNG_B64)
        user.avatar.attach(io: StringIO.new(bytes), filename: "demo_avatar.png", content_type: "image/png")
      end
      private_class_method :attach_avatar!

      def self.attach_product_image!(product, overwrite:)
        product.image.purge if overwrite && product.image.attached?

        bytes = read_jpeg_bytes_from_path_or_fallback(demo_product_path, fallback_b64: DEMO_PRODUCT_JPG_B64)
        product.image.attach(io: StringIO.new(bytes), filename: "demo_product.jpg", content_type: "image/jpeg")
      end
      private_class_method :attach_product_image!

      def self.demo_avatar_path
        Rails.root.join("lib/assets/demo_avatar.png")
      end
      private_class_method :demo_avatar_path

      def self.demo_product_path
        Rails.root.join("lib/assets/demo_product.jpg")
      end
      private_class_method :demo_product_path

      def self.read_png_bytes_from_path_or_fallback(path, fallback_b64:)
        read_image_bytes_from_path_or_fallback(
          path,
          expected_magic: "\x89PNG\r\n\x1A\n".b,
          fallback_b64: fallback_b64
        )
      end
      private_class_method :read_png_bytes_from_path_or_fallback

      def self.read_jpeg_bytes_from_path_or_fallback(path, fallback_b64:)
        read_image_bytes_from_path_or_fallback(
          path,
          expected_magic: "\xFF\xD8\xFF".b,
          fallback_b64: fallback_b64
        )
      end
      private_class_method :read_jpeg_bytes_from_path_or_fallback

      def self.read_image_bytes_from_path_or_fallback(path, expected_magic:, fallback_b64:)
        bytes = read_asset_bytes(path)
        return bytes if bytes.present? && bytes.start_with?(expected_magic)

        decoded = decode_base64_if_possible(bytes)
        return decoded if decoded.present? && decoded.start_with?(expected_magic)

        Base64.decode64(fallback_b64)
      end
      private_class_method :read_image_bytes_from_path_or_fallback

      def self.read_asset_bytes(path)
        return nil unless File.exist?(path)

        File.binread(path)
      rescue StandardError
        nil
      end
      private_class_method :read_asset_bytes

      def self.decode_base64_if_possible(bytes)
        return nil if bytes.blank?

        str = bytes.to_s.strip
        return nil if str.length < 16

        Base64.decode64(str)
      rescue ArgumentError
        nil
      end
      private_class_method :decode_base64_if_possible

      def self.ensure_user_avatars!
        users_scope.find_each do |user|
          next if user.avatar.attached? && user.avatar.blob&.persisted?

          attach_avatar!(user, overwrite: false)
        end
      end
      private_class_method :ensure_user_avatars!

      def self.ensure_product_images!
        Demo::Tasks::Scope.products_scope.find_each do |product|
          next if product.image.attached? && product.image.blob&.persisted?

          attach_product_image!(product, overwrite: false)
        end
      end
      private_class_method :ensure_product_images!
    end
  end
end
