class AddDmiStatusAndOrderNumberToOrders < ActiveRecord::Migration
  def change
    change_table :spree_orders do |t|
      t.string :dmi_status
      t.string :dmi_order_number
    end
  end
end
