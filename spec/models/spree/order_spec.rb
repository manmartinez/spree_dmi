describe Spree::Order, type: :model do 
  subject(:order) { create(:order) }
  it "downcases DMI status" do
    order.dmi_status = "ProCesseD"
    expect(order.dmi_status).to eq 'processed'
  end

  describe '#send_to_dmi_async' do 
    let(:order) { create(:order_ready_to_ship) }
    it "queues the job on sidekiq" do 
      expect{
        order.send_to_dmi_async
      }.to change(DMI::PlaceOrderWorker.jobs, :size).by(1)
    end
  end

  describe '.candidates_for_shipment_notice' do 
    let(:failed_orders) { create_list(:order_with_dmi_error, 3) }
    let(:not_shipped_orders) { create_list(:dmi_order_ready_to_ship, 3) }
    let(:candidates) { Spree::Order.candidates_for_shipment_notice.pluck(:id) }
    let(:shipped_orders) do 
      create_list(:shipped_dmi_order, 3).each do |o|
        # For some reason the spree factory sets shipment_state to ready (which is wrong)
        # and I couldn't override it on our child factory :(
        o.update_attribute(:shipment_state, :shipped) 
      end
    end

    before :each do
      failed_orders
      not_shipped_orders
      shipped_orders
    end

    it "doesn't return failed DMI orders" do 
      expect(candidates).to_not include(*failed_orders.map(&:id))
    end

    it "returns not shipped orders" do 
      expect(candidates).to include(*not_shipped_orders.map(&:id))
    end

    it "doesn't return shipped orders" do 
      expect(candidates).to_not include(*shipped_orders.map(&:id))
    end
  end
end
