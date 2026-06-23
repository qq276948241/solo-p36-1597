Sequel.migration do
  change do
    create_table :devices do
      primary_key :id
      String :name, null: false
      String :equipment_type, null: false
      String :model
      String :serial_number, unique: true
      String :status, null: false, default: 'available'
      String :description
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
