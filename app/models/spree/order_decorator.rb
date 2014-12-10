Spree::Order.class_eval do 
  state_machine do 
    after_transition to: :complete, do: :send_to_dmi
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

  def self.candidates_for_shipment_notice
    where(dmi_status: :processed).where.not(shipment_state: :shipped, dmi_order_number: nil)
  end

end
