require 'spec_helper'
require 'savon/mock/spec_helper'

describe DMI::Order do
  include Savon::SpecHelper 

  describe '.place' do 

    before(:each) { savon.mock! }
    after(:each) { savon.unmock! }

    context "for orders with registered SKUs" do 
      let(:order) { create(:order_ready_to_ship) }

      before(:each) do
        response = File.read("spec/fixtures/order_processed.xml")
        savon.expects(:place_order).with(message: :any).returns(response)
      end

      it "returns true" do 
        expect(DMI::Order.place(order)).to be true
      end

      it "updates the order accordingly" do 
        DMI::Order.place(order)
        order.reload
        expect(order.dmi_status).to eq 'processed'
        expect(order.dmi_notes).to be nil
        expect(order.dmi_order_number).to_not be nil
      end
    end

    context "for orders with unregistered SKUs" do
      let(:order) { create(:order_ready_to_ship) }

      before(:each) do 
        response = File.read("spec/fixtures/unregistered_skus.xml")
        savon.expects(:place_order).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(DMI::Order.place(order)).to be false
      end

      it "updates the order accordingly" do 
        DMI::Order.place(order)
        order.reload
        expect(order.dmi_status).to eq 'error'
        expect(order.dmi_notes).to_not be nil
      end
    end

    context "when something goes terribly wrong" do
      let(:order) { create(:order_ready_to_ship) } 

      before(:each) do 
        soap_fault = File.read("spec/fixtures/soap_fault.xml")
        response = { code: 500, headers: {}, body: soap_fault }
        savon.expects(:place_order).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(DMI::Order.place(order)).to be false
      end

      it "updates the order accordingly" do 
        DMI::Order.place(order)
        order.reload
        expect(order.dmi_status).to eq 'error'
      end

    end

  end
end
