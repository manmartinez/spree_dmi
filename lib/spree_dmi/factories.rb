FactoryGirl.define do
  factory :dmi_order_ready_to_ship, parent: :order_ready_to_ship do
    dmi_status 'processed'
    dmi_order_number { (1..8).map { rand(10) }.join }
  end

  factory :shipped_dmi_order, parent: :shipped_order do 
    dmi_status 'processed'
    dmi_order_number { (1..8).map { rand(10) }.join }
  end

  factory :dmi_order_with_pending_payments, parent: :completed_order_with_pending_payment do 
    dmi_status 'processed'
    dmi_order_number { (1..8).map { rand(10) }.join }
  end

  factory :order_with_dmi_error, parent: :order_ready_to_ship do 
    dmi_status 'error'
    dmi_order_number nil
  end

  factory :dmi_event, class: 'Spree::DmiEvent' do 
    event_type %w(info error success warning).sample
    description 'Sample description'
  end
end
