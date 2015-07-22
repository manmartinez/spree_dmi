require 'spec_helper'

describe DMI::ShipmentNoticeWorker do
  describe '#perform' do
    subject(:worker) { DMI::ShipmentNoticeWorker.new }
    let!(:orders) { create_list(:shipped_dmi_order, 25) }
    let(:first_batch) { orders[0..19] }
    let(:second_batch) { orders[20..24] }

    it 'process batches of 20 orders' do
      expect_any_instance_of(DMI::ShipmentNotice).to receive(:request_with_orders).with(first_batch).once
      expect_any_instance_of(DMI::ShipmentNotice).to receive(:request_with_orders).with(second_batch).once

      worker.perform
    end
  end
end
