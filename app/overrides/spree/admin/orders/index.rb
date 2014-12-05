Deface::Override.new(
  virtual_path: 'spree/admin/orders/index',
  name: 'add_dmi_column_headers',
  insert_before: '[data-hook="admin_orders_index_header_actions"]',
  partial: 'spree/admin/orders/dmi_column_headers'
)

Deface::Override.new(
  virtual_path: 'spree/admin/orders/index',
  name: 'add_dmi_column_values',
  insert_before: '[data-hook="admin_orders_index_row_actions"]',
  partial: 'spree/admin/orders/dmi_column_values'
)
