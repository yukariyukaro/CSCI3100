module Demo
  module Tasks
    module Users
      def self.ensure!(email:, name:)
        User.find_or_create_by!(email: email) do |user|
          user.name = name
          user.password = "password123"
          user.password_confirmation = "password123"
        end
      end
    end
  end
end
