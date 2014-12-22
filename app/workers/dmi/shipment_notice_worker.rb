class DMI::ShipmentNoticeWorker
  include Sidekiq::Worker 

  def perform
    notice = DMI::ShipmentNotice.new
    orders = Spree::Order.candidates_for_shipment_notice
    orders.each_slice(20) do |order_group|      
      notice.request_with_orders(order_group)
    end
  end
end
