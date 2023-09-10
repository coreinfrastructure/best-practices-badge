class MigrateEncryptedAttributes < ActiveRecord::Migration[7.0]
  def change
    add_column :user, :new_email, :string
    puts 'added col'
    datafix(User.all)
  end

  def datafix(users)
    users.each do |user|
      puts user.email
      user.new_email = user.email
      puts user.email
      user.save!
      puts 'save'
      puts user.new_email
    end
  end
end

