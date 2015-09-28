require 'spec_helper'

describe DMI::PlaceOrderWorker do
  describe '#perform' do
    subject(:worker) { DMI::PlaceOrderWorker.new }
    let!(:order) { create(:completed_order_with_totals) }

    it "sends the correct order to DMI" do
      expect_any_instance_of(Spree::Order).to receive(:send_to_dmi)
      worker.perform(order.id)
    end
  end
end
