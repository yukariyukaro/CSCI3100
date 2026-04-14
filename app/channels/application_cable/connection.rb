module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session = env["rack.session"]
      user_id = session&.[](:user_id) || session&.[]("user_id")
      verified = User.find_by(id: user_id)
      verified || reject_unauthorized_connection
    end
  end
end
