require 'sequel'
require 'bcrypt'

DB = Sequel.connect('sqlite://db/equipment.db')

require_relative '../models/user'
require_relative '../models/device'
require_relative '../models/borrow'

puts 'Creating admin user...'
admin = User.new(
  username: 'admin',
  name: '系统管理员',
  role: 'admin'
)
admin.password = 'admin123'
admin.save

puts 'Creating employee users...'
employee1 = User.new(
  username: 'zhangsan',
  name: '张三',
  role: 'employee'
)
employee1.password = '123456'
employee1.save

employee2 = User.new(
  username: 'lisi',
  name: '李四',
  role: 'employee'
)
employee2.password = '123456'
employee2.save

puts 'Creating devices...'
devices_data = [
  { name: 'ThinkPad X1 Carbon', equipment_type: '笔记本', device_model: 'X1 Carbon Gen 10', serial_number: 'NB-2024-001', description: '14寸商务笔记本' },
  { name: 'MacBook Pro 14', equipment_type: '笔记本', device_model: 'MacBook Pro 14 M3', serial_number: 'NB-2024-002', description: '14寸苹果笔记本' },
  { name: 'Epson CB-X50', equipment_type: '投影仪', device_model: 'CB-X50', serial_number: 'PJ-2024-001', description: '3600流明高清投影仪' },
  { name: 'Sony VPL-EX430', equipment_type: '投影仪', device_model: 'VPL-EX430', serial_number: 'PJ-2024-002', description: '3200流明便携投影仪' },
  { name: 'Canon EOS R6', equipment_type: '相机', device_model: 'EOS R6 Mark II', serial_number: 'CAM-2024-001', description: '全画幅微单相机' },
  { name: 'Sony A7M4', equipment_type: '相机', device_model: 'Alpha 7 IV', serial_number: 'CAM-2024-002', description: '全画幅微单相机' },
  { name: 'DJI Pocket 2', equipment_type: '相机', device_model: 'Pocket 2', serial_number: 'CAM-2024-003', description: '口袋云台相机' },
  { name: 'iPad Pro 12.9', equipment_type: '平板', device_model: 'iPad Pro 12.9 M2', serial_number: 'TB-2024-001', description: '12.9寸平板电脑' },
]

devices_data.each do |data|
  Device.create(data.merge(status: 'available'))
end

puts 'Creating borrow records for testing...'
device1 = Device.first(serial_number: 'NB-2024-001')
device2 = Device.first(serial_number: 'CAM-2024-001')
zhangsan = User.first(username: 'zhangsan')
lisi = User.first(username: 'lisi')

overdue_borrow = Borrow.new(
  user_id: zhangsan.id,
  device_id: device1.id,
  borrowed_at: DateTime.now - 35,
  expected_return_date: Date.today - 5,
  purpose: '项目开发使用',
  status: 'borrowed'
)
overdue_borrow.save
device1.update(status: 'borrowed')

normal_borrow = Borrow.new(
  user_id: lisi.id,
  device_id: device2.id,
  borrowed_at: DateTime.now - 3,
  expected_return_date: Date.today + 7,
  purpose: '拍摄公司宣传片',
  status: 'borrowed'
)
normal_borrow.save
device2.update(status: 'borrowed')

puts 'Seed data created successfully!'
puts "Admin: admin / admin123"
puts "Employees: zhangsan / 123456, lisi / 123456"
puts "Overdue borrow: zhangsan borrowed ThinkPad X1 Carbon (5 days overdue)"
puts "Normal borrow: lisi borrowed Canon EOS R6 (due in 7 days)"
