Spree::Order.class_eval do 
  state_machine do 
    after_transition to: :complete, do: :send_to_dmi
  end

  def send_to_dmi
    DMI::Order.place(self)
  end
end
