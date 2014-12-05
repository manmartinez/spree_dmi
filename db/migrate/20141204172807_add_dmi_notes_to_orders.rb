class AddDmiNotesToOrders < ActiveRecord::Migration
  def change
    change_table :spree_orders do |t|
      t.string :dmi_notes
    end
  end
end
