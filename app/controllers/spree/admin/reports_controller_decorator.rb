Spree::Admin::ReportsController.class_eval do 
  add_available_report! :dmi_events

  def dmi_events
    @events = Spree::DmiEvent.order(created_at: :desc)
  end
end