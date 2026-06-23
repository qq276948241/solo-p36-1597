module BorrowsRoutes
  def self.registered(app)
    app.helpers do
      def json_list(data)
        { borrows: data.map(&:to_h), count: data.length }.to_json
      end

      def handle_borrow_errors
        yield
      rescue Borrow::ValidationError => e
        halt 400, { error: e.message }.to_json
      rescue Borrow::NotFoundError => e
        halt 404, { error: e.message }.to_json
      rescue Borrow::ForbiddenError => e
        halt 403, { error: e.message }.to_json
      end
    end

    app.get '/api/borrows/overdue' do
      authorize_admin!
      json_list Borrow.overdue.all
    end

    app.get '/api/borrows/current' do
      authenticate!
      json_list Borrow.current_borrowed.all
    end

    app.get '/api/borrows/my' do
      authenticate!
      json_list Borrow.by_user(current_user.id).all
    end

    app.get '/api/borrows' do
      authorize_admin!
      json_list Borrow.filtered(params).all
    end

    app.get '/api/borrows/:id' do
      authenticate!
      handle_borrow_errors do
        borrow = Borrow[params['id']]
        raise Borrow::NotFoundError, '借用记录不存在' unless borrow
        borrow.ensure_viewable_by!(current_user)
        { borrow: borrow.to_h }.to_json
      end
    end

    app.post '/api/borrows' do
      authenticate!
      handle_borrow_errors do
        p = json_params
        borrow = Borrow.create_borrow(
          user: current_user,
          device_id: p['device_id'],
          expected_return_date_str: p['expected_return_date'],
          purpose: p['purpose']
        )
        status 201
        { message: '借用申请成功', borrow: borrow.to_h }.to_json
      end
    end

    app.post '/api/borrows/:id/return' do
      authenticate!
      handle_borrow_errors do
        borrow = Borrow[params['id']]
        raise Borrow::NotFoundError, '借用记录不存在' unless borrow
        borrow.ensure_returnable_by!(current_user)
        days = borrow.process_return!
        {
          message: '设备归还成功',
          borrow_days: days,
          borrow: borrow.to_h
        }.to_json
      end
    end

    app.delete '/api/borrows/:id' do
      authorize_admin!
      handle_borrow_errors do
        borrow = Borrow[params['id']]
        raise Borrow::NotFoundError, '借用记录不存在' unless borrow
        borrow.destroy_safely!
        { message: '借用记录删除成功' }.to_json
      end
    end
  end
end
