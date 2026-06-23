Sequel.migration do
  change do
    rename_column :devices, :model, :device_model
  end
end
