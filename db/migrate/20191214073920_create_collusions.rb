# frozen_string_literal: true

class CreateCollusions < ActiveRecord::Migration[6.0]
  def up
    create_table :collusions do |t|
      t.belongs_to :post
      t.belongs_to :user
      t.integer :version, null: false, default: 1
      t.jsonb :changeset
      t.text :value
    end

    add_index :collusions, [:post_id, :version], unique: true
  end

  def down
    drop_table :collusions
  end
end
