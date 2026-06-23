module DevicesRoutes
  def self.registered(app)
    app.get '/api/devices' do
      authenticate!

      dataset = Device.dataset

      if params['type']
        dataset = dataset.where(equipment_type: params['type'])
      end

      if params['status']
        dataset = dataset.where(status: params['status'])
      end

      devices = dataset.order(:id).all.map(&:to_h)
      { devices: devices, count: devices.length }.to_json
    end

    app.get '/api/devices/types' do
      authenticate!
      types = Device.select_map(:equipment_type).uniq
      { types: types }.to_json
    end

    app.get '/api/devices/:id' do
      authenticate!
      device = Device[params['id']]
      halt 404, { error: '设备不存在' }.to_json unless device

      result = device.to_h
      if device.borrowed?
        current_borrow = device.current_borrow
        result[:current_borrow] = current_borrow&.to_h
      end
      { device: result }.to_json
    end

    app.post '/api/devices' do
      authorize_admin!
      params = json_params

      required = %w[name equipment_type]
      missing = required.select { |k| params[k].to_s.empty? }
      if missing.any?
        halt 400, { error: "缺少必填字段: #{missing.join(', ')}" }.to_json
      end

      if params['serial_number'] && Device.first(serial_number: params['serial_number'])
        halt 400, { error: '序列号已存在' }.to_json
      end

      device = Device.new(
          name: params['name'],
          equipment_type: params['equipment_type'],
          device_model: params['model'],
          serial_number: params['serial_number'],
          description: params['description'],
          status: 'available'
        )

      if device.save
        status 201
        { message: '设备创建成功', device: device.to_h }.to_json
      else
        halt 400, { error: '创建设备失败', details: device.errors }.to_json
      end
    end

    app.put '/api/devices/:id' do
      authorize_admin!
      device = Device[params['id']]
      halt 404, { error: '设备不存在' }.to_json unless device

      params = json_params

      updates = {}
        updates[:name] = params['name'] if params.key?('name')
        updates[:equipment_type] = params['equipment_type'] if params.key?('equipment_type')
        updates[:device_model] = params['model'] if params.key?('model')
        updates[:serial_number] = params['serial_number'] if params.key?('serial_number')
        updates[:description] = params['description'] if params.key?('description')

      if params['serial_number'] && params['serial_number'] != device.serial_number
        if Device.first(serial_number: params['serial_number'])
          halt 400, { error: '序列号已存在' }.to_json
        end
      end

      if device.update(updates)
        { message: '设备更新成功', device: device.to_h }.to_json
      else
        halt 400, { error: '更新设备失败', details: device.errors }.to_json
      end
    end

    app.delete '/api/devices/:id' do
      authorize_admin!
      device = Device[params['id']]
      halt 404, { error: '设备不存在' }.to_json unless device

      if device.borrowed?
        halt 400, { error: '设备正在借用中，无法删除' }.to_json
      end

      device.delete
      { message: '设备删除成功' }.to_json
    end
  end
end
