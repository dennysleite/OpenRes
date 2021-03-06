# -*- encoding : utf-8 -*-
class CreateJustifications < ActiveRecord::Migration
  def change
    create_table :justifications do |t|
      t.text :reason
      t.references :reservation, index: true
      t.references :user, index: true
      t.references :reservation_group, index: true

      t.timestamps
    end
  end
end
