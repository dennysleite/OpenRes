# -*- encoding : utf-8 -*-
class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :name
      t.string :code
      t.integer :capacity
      t.boolean :reservable
      #t.references :sector, index: true
      t.references :room_type, index: true

      t.timestamps
    end
  end
end
