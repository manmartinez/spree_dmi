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
end