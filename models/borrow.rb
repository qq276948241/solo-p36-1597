class Borrow < Sequel::Model
  class ValidationError < StandardError; end
  class NotFoundError < StandardError; end
  class ForbiddenError < StandardError; end

  plugin :timestamps, update_on_create: true

  many_to_one :user
  many_to_one :device

  dataset_module do
    def overdue
      where(status: 'borrowed')
        .where(Sequel.lit('expected_return_date IS NOT NULL AND expected_return_date < ?', Date.today))
        .order(Sequel.asc(:expected_return_date))
    end

    def current_borrowed
      where(status: 'borrowed').order(:borrowed_at)
    end

    def by_user(user_id)
      where(user_id: user_id).order(Sequel.desc(:borrowed_at))
    end

    def filtered(params)
      ds = self
      ds = ds.where(status: params['status']) if params['status']
      ds = ds.where(user_id: params['user_id']) if params['user_id']
      ds = ds.where(device_id: params['device_id']) if params['device_id']
      ds.order(Sequel.desc(:borrowed_at))
    end
  end

  def self.parse_expected_return_date(date_str)
    raise ValidationError, '请填写预计归还日期' if date_str.to_s.empty?
    begin
      date = Date.parse(date_str)
    rescue ArgumentError
      raise ValidationError, '预计归还日期格式无效，请使用YYYY-MM-DD格式'
    end
    raise ValidationError, '预计归还日期必须晚于今天' if date <= Date.today
    date
  end

  def self.create_borrow(user:, device_id:, expected_return_date_str:, purpose: nil)
    raise ValidationError, '请选择要借用的设备' if device_id.to_s.empty?

    device = Device[device_id]
    raise NotFoundError, '设备不存在' unless device
    raise ValidationError, '设备已被借出，请选择其他设备' if device.borrowed?

    expected_date = parse_expected_return_date(expected_return_date_str)

    borrow = new(
      user_id: user.id,
      device_id: device.id,
      borrowed_at: DateTime.now,
      expected_return_date: expected_date,
      purpose: purpose,
      status: 'borrowed'
    )

    DB.transaction do
      unless borrow.save
        raise ValidationError, borrow.errors.full_messages.join(', ') rescue "借用申请失败"
      end
      device.mark_as_borrowed
    end

    borrow
  end

  def ensure_viewable_by!(user)
    return if user.admin? || user_id == user.id
    raise ForbiddenError, '无权查看此记录'
  end

  def ensure_returnable_by!(user)
    raise ValidationError, '该设备已归还' unless status == 'borrowed'
    return if user.admin? || user_id == user.id
    raise ForbiddenError, '无权归还此设备'
  end

  def process_return!
    DB.transaction do
      returned_at_time = DateTime.now
      diff_seconds = (returned_at_time.to_time - borrowed_at.to_time).to_i
      days = (diff_seconds / 86400.0).ceil
      days = 1 if days < 1
      update(
        returned_at: returned_at_time,
        borrow_days: days,
        status: 'returned'
      )
      device.mark_as_available
    end
    borrow_days
  end

  def destroy_safely!
    DB.transaction do
      device.mark_as_available if status == 'borrowed'
      delete
    end
  end

  def overdue?
    status == 'borrowed' && expected_return_date && Date.today > expected_return_date
  end

  def overdue_days
    return 0 unless overdue?
    (Date.today - expected_return_date).to_i
  end

  def to_h
    h = {
      id: id,
      user_id: user_id,
      user_name: user&.name,
      device_id: device_id,
      device_name: device&.name,
      device_type: device&.equipment_type,
      borrowed_at: borrowed_at,
      expected_return_date: expected_return_date,
      returned_at: returned_at,
      borrow_days: borrow_days,
      purpose: purpose,
      status: status,
      created_at: created_at,
      updated_at: updated_at
    }
    if overdue?
      h[:overdue] = true
      h[:overdue_days] = overdue_days
    end
    h
  end
end
