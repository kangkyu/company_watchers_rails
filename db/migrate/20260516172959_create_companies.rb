class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :symbol
      t.string :name
      t.string :sector
      t.string :industry
      t.string :ceo
      t.string :country
      t.string :website
      t.string :image
      t.text :description
      t.string :market_cap
      t.integer :status, default: 0, null: false
      t.datetime :blocked_at

      t.timestamps
    end
    add_index :companies, :symbol, unique: true
  end
end
