class Borrow < Sequel::Model
  plugin :timestamps, update_on_create: true

  many_to_one :user
  many_to_one :device

  def overdue?
    status == 'borrowed' && expected_return_date && Date.today > expected_return_date
  end

  def overdue_days
    return 0 unless overdue?
    (Date.today - expected_return_date).to_i
  end

  def return!
    returned_at = DateTime.now
    diff_seconds = (returned_at.to_time - borrowed_at.to_time).to_i
    borrow_days = (diff_seconds / 86400.0).ceil
    borrow_days = 1 if borrow_days < 1
    update(
      returned_at: returned_at,
      borrow_days: borrow_days,
      status: 'returned'
    )
    device.mark_as_available
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
