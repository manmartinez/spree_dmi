require 'spec_helper'
require 'savon/mock/spec_helper'

describe DMI::ShipmentNotice do
  include Savon::SpecHelper 

  describe '#request_with_orders' do 

    before(:each) { savon.mock! }
    after(:each) { savon.unmock! }
    subject(:shipment_notice) { DMI::ShipmentNotice.new }

    context "for shipped orders in DMI" do 

      let(:orders) do
        %w(26110861 26110862).map do |dmi_order_number| 
          create(:dmi_order_ready_to_ship, dmi_order_number: dmi_order_number)
        end
      end

      # FIXME: it might be a better option to build the response so that
      # OrderNumber nodes match the ones FactoryGirl produces for
      # time reasons we're hard coding this bit
      before(:each) do
        response = File.read("spec/fixtures/shipment_notice/shipped_orders.xml")
        savon.expects(:request_shipment_notice_xml).with(message: :any).returns(response)
      end

      it "returns true" do 
        expect(shipment_notice.request_with_orders(orders)).to be true
      end

      it "marks orders as shipped" do 
        shipment_notice.request_with_orders(orders)
        orders.each do |order|
          expect(order.reload.shipped?).to be true
        end
      end

      it "sets tracking information" do 
        shipment_notice.request_with_orders(orders)
        orders.each do |order|
          order.shipments.each do |shipment|
            expect(shipment.tracking).to_not be_blank
          end
        end
      end

      it "marks shipments as shipped" do 
        shipment_notice.request_with_orders(orders)
        orders.each do |order|
          order.shipments.each do |shipment|
            expect(shipment.shipped?).to be true
          end
        end
      end
    end

    context "for non-shipped orders in DMI" do 
      
      let(:orders) do
        %w(26110867 26110868).map do |dmi_order_number| 
          create(:dmi_order_ready_to_ship, dmi_order_number: dmi_order_number)
        end
      end

      before(:each) do
        response = File.read("spec/fixtures/shipment_notice/unshipped_orders.xml")
        savon.expects(:request_shipment_notice_xml).with(message: :any).returns(response)
      end

      it "doesn't mark orders as shipped" do 
        shipment_notice.request_with_orders(orders)
        orders.each do |order|
          expect(order.reload.shipped?).to be false
        end
      end

      it "returns true" do 
        expect(shipment_notice.request_with_orders(orders)).to be true
      end

    end

    context "when there's an unknown error" do 
      let(:orders) { create_list(:dmi_order_ready_to_ship, 3) }

      before(:each) do
        response = File.read("spec/fixtures/shipment_notice/unknown_error.xml")
        savon.expects(:request_shipment_notice_xml).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(shipment_notice.request_with_orders(orders)).to be false
      end

      it "logs the error" do 
        expect{
          shipment_notice.request_with_orders(orders)  
        }.to change(Spree::DmiEvent.error, :count).by(1)
      end
    end

    context "when there's an error with the order" do 
      let(:order) { create(:dmi_order_ready_to_ship, dmi_order_number: '12345678') }

      before(:each) do 
        response = File.read("spec/fixtures/shipment_notice/order_error.xml")
        savon.expects(:request_shipment_notice_xml).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(shipment_notice.request_with_orders([order])).to be false
      end

      it "updates the order information" do 
        shipment_notice.request_with_orders([order])
        order.reload
        expect(order.dmi_status).to eq 'error'
        expect(order.dmi_notes).to eq 'Invalid OrderNumber in Order'
      end
    end

    context "when something goes terribly wrong" do
      let(:orders) { create_list(:dmi_order_ready_to_ship, 3) }

      before(:each) do 
        soap_fault = File.read("spec/fixtures/shared/soap_fault.xml")
        response = { code: 500, headers: {}, body: soap_fault }
        savon.expects(:request_shipment_notice_xml).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(shipment_notice.request_with_orders(orders)).to be false
      end
    end

  end
end
