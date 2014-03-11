# -*- encoding : utf-8 -*-
class CreateReservationGroups < ActiveRecord::Migration
  def change
    create_table :reservation_groups do |t|
      t.string :name
      t.text :notes

      t.references :user

      t.timestamps
    end
  end
end
