require 'bcrypt'

class User < Sequel::Model
  plugin :timestamps, update_on_create: true

  one_to_many :borrows

  def password=(password)
    self.password_digest = BCrypt::Password.create(password)
  end

  def authenticate(password)
    BCrypt::Password.new(password_digest) == password
  end

  def admin?
    role == 'admin'
  end

  def employee?
    role == 'employee'
  end

  def to_h
    {
      id: id,
      username: username,
      name: name,
      role: role,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
