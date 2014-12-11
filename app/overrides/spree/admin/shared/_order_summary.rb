Deface::Override.new(
  virtual_path: 'spree/admin/shared/_order_summary',
  name: 'add_dmi_order_information',
  insert_bottom: '#order_tab_summary .additional-info',
  partial: 'spree/admin/shared/dmi_order_summary'
)

Deface::Override.new(
  virtual_path: 'spree/admin/shared/_order_summary',
  name: 'add_dmi_notes',
  insert_bottom: '#order_tab_summary',
  partial: 'spree/admin/shared/dmi_order_notes'
)
