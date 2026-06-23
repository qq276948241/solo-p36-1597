Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :username, null: false, unique: true
      String :password_digest, null: false
      String :name, null: false
      String :role, null: false, default: 'employee'
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
