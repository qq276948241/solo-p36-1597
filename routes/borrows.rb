module BorrowsRoutes
  def self.registered(app)
    app.get '/api/borrows/current' do
      authenticate!
      borrows = Borrow.where(status: 'borrowed')
                      .order(:borrowed_at)
                      .all
                      .map(&:to_h)
      { borrows: borrows, count: borrows.length }.to_json
    end

    app.get '/api/borrows/my' do
      authenticate!
      borrows = Borrow.where(user_id: current_user.id)
                      .order(Sequel.desc(:borrowed_at))
                      .all
                      .map(&:to_h)
      { borrows: borrows, count: borrows.length }.to_json
    end

    app.get '/api/borrows' do
      authorize_admin!
      dataset = Borrow.dataset

      if params['status']
        dataset = dataset.where(status: params['status'])
      end

      if params['user_id']
        dataset = dataset.where(user_id: params['user_id'])
      end

      if params['device_id']
        dataset = dataset.where(device_id: params['device_id'])
      end

      borrows = dataset.order(Sequel.desc(:borrowed_at)).all.map(&:to_h)
      { borrows: borrows, count: borrows.length }.to_json
    end

    app.get '/api/borrows/:id' do
      authenticate!
      borrow = Borrow[params['id']]
      halt 404, { error: '借用记录不存在' }.to_json unless borrow

      if !current_user.admin? && borrow.user_id != current_user.id
        halt 403, { error: '无权查看此记录' }.to_json
      end

      { borrow: borrow.to_h }.to_json
    end

    app.post '/api/borrows' do
      authenticate!
      params = json_params

      if params['device_id'].to_s.empty?
        halt 400, { error: '请选择要借用的设备' }.to_json
      end

      device = Device[params['device_id']]
      halt 404, { error: '设备不存在' }.to_json unless device

      if device.borrowed?
        halt 400, { error: '设备已被借出，请选择其他设备' }.to_json
      end

      borrow = Borrow.new(
        user_id: current_user.id,
        device_id: device.id,
        borrowed_at: DateTime.now,
        purpose: params['purpose'],
        status: 'borrowed'
      )

      DB.transaction do
        if borrow.save
          device.mark_as_borrowed
          status 201
          { message: '借用申请成功', borrow: borrow.to_h }.to_json
        else
          halt 400, { error: '借用申请失败', details: borrow.errors }.to_json
        end
      end
    end

    app.post '/api/borrows/:id/return' do
      authenticate!
      borrow = Borrow[params['id']]
      halt 404, { error: '借用记录不存在' }.to_json unless borrow

      if borrow.status != 'borrowed'
        halt 400, { error: '该设备已归还' }.to_json
      end

      if !current_user.admin? && borrow.user_id != current_user.id
        halt 403, { error: '无权归还此设备' }.to_json
      end

      DB.transaction do
        borrow.return!
        {
          message: '设备归还成功',
          borrow_days: borrow.borrow_days,
          borrow: borrow.to_h
        }.to_json
      end
    end

    app.delete '/api/borrows/:id' do
      authorize_admin!
      borrow = Borrow[params['id']]
      halt 404, { error: '借用记录不存在' }.to_json unless borrow

      if borrow.status == 'borrowed'
        borrow.device.mark_as_available
      end

      borrow.delete
      { message: '借用记录删除成功' }.to_json
    end
  end
end
