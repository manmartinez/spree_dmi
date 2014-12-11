require 'spec_helper'
require 'savon/mock/spec_helper'

describe DMI::ShipmentNotice do
  include Savon::SpecHelper 

  describe '#request_with_orders' do 

    before(:each) { savon.mock! }
    after(:each) { savon.unmock! }

    context "for shipped orders in DMI" do 
      subject(:shipment_notice) { DMI::ShipmentNotice.new }

      let(:orders) do
        %w(26110861 26110862).map do |dmi_order_number| 
          create(:dmi_order_ready_to_ship, dmi_order_number: dmi_order_number)
        end
      end

      # FIXME: it might be a better option to build the response so that
      # OrderNumber nodes match the ones FactoryGirl produces for
      # time reasons we're hard coding this bit
      before(:each) do
        response = File.read("spec/fixtures/shipped_orders.xml")
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
      subject(:shipment_notice) { DMI::ShipmentNotice.new }
      
      let(:orders) { create_list(:dmi_order_ready_to_ship, 3) }

      before(:each) do
        response = File.read("spec/fixtures/shipped_orders.xml")
        savon.expects(:request_shipment_notice_xml).with(message: :any).returns(response)
      end

      it "doesn't mark orders as shipped" do 
        shipment_notice.request_with_orders(orders)
        orders.each do |order|
          expect(order.reload.shipped?).to be false
        end
      end

    end

  end
end
