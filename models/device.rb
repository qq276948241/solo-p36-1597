class Device < Sequel::Model
  plugin :timestamps, update_on_create: true

  one_to_many :borrows

  def available?
    status == 'available'
  end

  def borrowed?
    status == 'borrowed'
  end

  def mark_as_borrowed
    this.update(status: 'borrowed')
    reload
  end

  def mark_as_available
    this.update(status: 'available')
    reload
  end

  def current_borrow
    borrows_dataset.where(status: 'borrowed').order(:borrowed_at).last
  end

  def to_h
    {
      id: id,
      name: name,
      equipment_type: equipment_type,
      model: device_model,
      serial_number: serial_number,
      status: status,
      description: description,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
