describe Spree::Order, type: :model do 
  subject(:order) { create(:order) }
  it "downcases DMI status" do
    order.dmi_status = "ProCesseD"
    expect(order.dmi_status).to eq 'processed'
  end
end