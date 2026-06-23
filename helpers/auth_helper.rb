require 'jwt'

module AuthHelper
  SECRET_KEY = ENV['JWT_SECRET'] || 'equipment-borrow-secret-key-2026'

  def encode_token(payload)
    payload[:exp] = (Time.now + 24 * 60 * 60).to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def decode_token(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')
    decoded[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def current_user
    return @current_user if @current_user

    auth_header = env['HTTP_AUTHORIZATION']
    return nil unless auth_header

    token = auth_header.split(' ').last
    decoded = decode_token(token)
    return nil unless decoded

    @current_user = User[decoded['user_id']]
  end

  def authenticate!
    unless current_user
      halt 401, { error: '未授权，请先登录' }.to_json
    end
  end

  def authorize_admin!
    authenticate!
    unless current_user.admin?
      halt 403, { error: '权限不足，需要管理员权限' }.to_json
    end
  end

  def json_params
    @json_params ||= begin
      body = request.body.read
      body.empty? ? {} : JSON.parse(body)
    end
  rescue JSON::ParserError
    halt 400, { error: 'JSON格式错误' }.to_json
  end
end
