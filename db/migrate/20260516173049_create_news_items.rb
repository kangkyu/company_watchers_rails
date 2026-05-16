class CreateNewsItems < ActiveRecord::Migration[8.1]
  def change
    create_table :news_items do |t|
      t.references :company, null: false, foreign_key: true
      t.string :external_id
      t.string :url
      t.string :title
      t.string :image
      t.string :source
      t.string :site
      t.text :snippet
      t.datetime :published_at

      t.timestamps
    end
    add_index :news_items, :external_id, unique: true
  end
end
