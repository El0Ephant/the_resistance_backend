module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      self.current_user = find_verified_user
    end
    def find_verified_user
      # request.params[:token] or something like: request.authorization.split(' ')[1]
      begin
        puts request.headers.to_h
        jwt_payload = JWT.decode(request.headers[:Authorization].split(' ')[1],
                                 ENV['DEVISE_JWT_SECRET_KEY']).first
      rescue JWT::ExpiredSignature
        logger.error "A connection attempt was rejected due to an expired token"
        close(reason: 'Token has expired', reconnect: false) if websocket.alive?
        return
      end
      user_id = jwt_payload['sub']
      User.find(user_id.to_s) || reject_unauthorized_connection
    end
  end
end
