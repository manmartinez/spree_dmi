class CreateSpreeDmiEvents < ActiveRecord::Migration
  def change
    create_table :spree_dmi_events do |t|
      t.string :event_type
      t.text :description
      t.timestamps
    end
  end
end
