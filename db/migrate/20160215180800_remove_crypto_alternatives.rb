class RemoveCryptoAlternatives < ActiveRecord::Migration
  def up
    remove_column :projects, :crypto_alternatives_status
    remove_column :projects, :crypto_alternatives_justification
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
