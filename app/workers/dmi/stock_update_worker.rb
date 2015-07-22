class DMI::StockUpdateWorker
  include Sidekiq::Worker

  def perform
    catalog = DMI::Catalog.new
    variants = Spree::Variant.where(track_inventory: true)
    variants.find_in_batches(batch_size: 20) do |variant_group|
      catalog.request_availability(variant_group)
    end
  end
end
