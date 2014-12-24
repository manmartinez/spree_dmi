FactoryGirl.define do
  factory :dmi_order_ready_to_ship, parent: :order_ready_to_ship do
    dmi_status 'processed'
    dmi_order_number { (1..8).map { rand(10) }.join }
  end

  factory :dmi_event, class: 'Spree::DmiEvent' do 
    event_type %w(info error success warning).sample
    description 'Sample description'
  end
end
