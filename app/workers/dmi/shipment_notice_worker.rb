class DMI::ShipmentNoticeWorker
  include Sidekiq::Worker

  def perform
    notice = DMI::ShipmentNotice.new
    orders = Spree::Order.candidates_for_shipment_notice
    orders.find_in_batches(batch_size: 20) do |order_group|
      notice.request_with_orders(order_group)
    end
  end
end
