Spree::Order.class_eval do
  state_machine do
    after_transition to: :complete, do: :send_to_dmi_async
  end

  # Internal: Send the order to DMI asynchronously using sidekiq.
  #
  # Returns nothing
  def send_to_dmi_async
    DMI::PlaceOrderWorker.perform_async(self.id)
  end

  # Public: Send this order to DMI
  #
  # Returns true if the order was placed successfully in DMI, false otherwise
  def send_to_dmi
    DMI::Order.place(self)
  end

  # Public: Set the dmi_status column
  #
  # status - The DMI status
  #
  # Returns the status set.
  def dmi_status=(status)
    write_attribute(:dmi_status, status.downcase)
  end

  # Public: True if this order has errors with DMI.
  #
  # Returns true if this order has errors with DMI, false otherwise
  def dmi_error?
    dmi_status == 'error'
  end

  def self.candidates_for_shipment_notice
    where.not(shipment_state: :shipped, dmi_order_number: nil, dmi_status: :error)
  end

end
