module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', current_user.name if current_user
    end

    protected

    def find_verified_user
      if cookies.signed['user.id'].present?
        verified_user = User.find_by(id: cookies.signed['user.id'])
        verified_user if verified_user && cookies.signed['user.expires_at'] > Time.now
      end
    end
  end
end