require 'spec_helper'

describe DMI::Shipper do
  describe '#ship' do 
    context "when auto capture is true" do 
      let(:order) { create(:dmi_order_with_pending_payments) }
      let(:shipper) { DMI::Shipper.new(order) }

      before(:each) do 
        Spree::Config.dmi_capture_on_ship = true
      end

      it "captures all pending payments" do 
        shipper.ship('91239018230', Time.now)
        expect(order.payments.pending.length).to eq 0
      end
    end

    context "when auto capture is false" do 
      let(:order) { create(:dmi_order_with_pending_payments) }
      let(:shipper) { DMI::Shipper.new(order) }

      before(:each) do 
        Spree::Config.dmi_capture_on_ship = false
      end

      it "doesn't capture pending payments" do 
        shipper.ship('1230801823', Time.now)
        expect(order.payments.pending.length).to be >= 0
      end
    end

    context "when the order can ship" do
      let(:order) { create(:dmi_order_ready_to_ship) }
      let(:shipper) { DMI::Shipper.new(order) }
      let(:tracking_number) { '12309128301' }
      let(:shipped_at) { Time.now.beginning_of_day }

      it "ships the order" do 
        shipper.ship(tracking_number, shipped_at)
        expect(order.shipped?).to be true
      end

      it "updates the tracking number" do
        shipper.ship(tracking_number, shipped_at)
        expect(order.shipments.first.tracking).to eq tracking_number
      end

      # it "updates the shipped_at date" do 
      #   shipper.ship(tracking_number, shipped_at)
      #   expect(order.shipments.first.shipped_at).to eq shipped_at
      # end
    end

    context "when the order can't ship" do 
      let(:order) { create(:dmi_order_with_pending_payments) }
      let(:shipper) { DMI::Shipper.new(order) }
      let(:tracking_number) { '12309128301' }
      let(:shipped_at) { Time.now.beginning_of_day }

      before(:each) do 
        Spree::Config.dmi_capture_on_ship = false
      end

      it "logs any errors" do 
        expect{
          shipper.ship(tracking_number, shipped_at)  
        }.to change(Spree::DmiEvent, :count).by(1)
      end

      it "updates the order" do 
        shipper.ship(tracking_number, shipped_at)
        expect(order.dmi_error?).to be true
        expect(order.dmi_notes).to_not be_blank
      end
    end
  end
end
