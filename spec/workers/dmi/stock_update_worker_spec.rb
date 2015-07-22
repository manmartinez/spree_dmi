require 'spec_helper'
require 'pry'

describe DMI::StockUpdateWorker do
  describe '#perform' do
    subject(:worker) { DMI::StockUpdateWorker.new }
    let!(:variants) { create_list(:master_variant, 25, track_inventory: true) }

    it 'process batches of 20 variants' do
      # FIXME: a callback in Spree is duplicating the variants created :(
      Spree::Variant.where.not(id: variants.map(&:id)).destroy_all

      expect_any_instance_of(DMI::Catalog).to receive(:request_availability).twice
      worker.perform
    end
  end
end
