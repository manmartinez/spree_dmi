class DMI::PlaceOrderWorker
  include Sidekiq::Worker 

  def perform(order_id)
    order = Spree::Order.find(order_id)
    order.send_to_dmi
  end
end
