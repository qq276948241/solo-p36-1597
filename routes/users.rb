module UsersRoutes
  def self.registered(app)
    app.post '/api/users/register' do
      params = json_params

      required = %w[username password name]
      missing = required.select { |k| params[k].to_s.empty? }
      if missing.any?
        halt 400, { error: "缺少必填字段: #{missing.join(', ')}" }.to_json
      end

      if User.first(username: params['username'])
        halt 400, { error: '用户名已存在' }.to_json
      end

      user = User.new(
        username: params['username'],
        name: params['name'],
        role: params['role'] || 'employee'
      )
      user.password = params['password']

      if user.save
        token = encode_token(user_id: user.id)
        {
          message: '注册成功',
          token: token,
          user: user.to_h
        }.to_json
      else
        halt 400, { error: '注册失败', details: user.errors }.to_json
      end
    end

    app.post '/api/users/login' do
      params = json_params

      if params['username'].to_s.empty? || params['password'].to_s.empty?
        halt 400, { error: '请输入用户名和密码' }.to_json
      end

      user = User.first(username: params['username'])
      unless user && user.authenticate(params['password'])
        halt 401, { error: '用户名或密码错误' }.to_json
      end

      token = encode_token(user_id: user.id)
      {
        message: '登录成功',
        token: token,
        user: user.to_h
      }.to_json
    end

    app.get '/api/users/me' do
      authenticate!
      { user: current_user.to_h }.to_json
    end

    app.get '/api/users' do
      authorize_admin!
      users = User.all.map(&:to_h)
      { users: users }.to_json
    end

    app.get '/api/users/:id' do
      authorize_admin!
      user = User[params['id']]
      halt 404, { error: '用户不存在' }.to_json unless user
      { user: user.to_h }.to_json
    end
  end
end
