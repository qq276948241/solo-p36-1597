Sequel.migration do
  change do
    create_table :borrows do
      primary_key :id
      foreign_key :user_id, :users, null: false
      foreign_key :device_id, :devices, null: false
      DateTime :borrowed_at, null: false
      DateTime :returned_at
      Integer :borrow_days
      String :purpose
      String :status, null: false, default: 'borrowed'
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
