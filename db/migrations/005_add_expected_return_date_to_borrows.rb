Sequel.migration do
  change do
    alter_table :borrows do
      add_column :expected_return_date, Date, null: true
    end
  end
end
