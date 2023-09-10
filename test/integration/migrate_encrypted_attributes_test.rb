# frozen_string_literal: true

require Rails.root.join(
  'db',
  'migrate',
  '20230815224759_migrate_encrypted_attributes.rb'
)

require 'test_helper'
class MigrateEncryptedAttributesTest < ActionDispatch::IntegrationTest
  test 'properly migrates user email to new scheme' do
    @migration = MigrateEncryptedAttributes.new
    @migration.datafix(User.all)
    @user = users(:test_user)
    email = @user.email.clone
    @migration.up
    @user.reload
    puts 'new' + (@user.new_email || "")
    puts 'old' + @user.email || ""
    puts 'string' + email
    assert @user.new_email == email
    @migration.down
    @user.reload
    puts 'new' + @user.new_email || ""
    puts 'old' + @user.email || ""
    puts 'string' + email
    assert @user.email == email
    assert @user.new_email.nil?
  end
end
