class DMI::StockUpdateWorker
  include Sidekiq::Worker 

  def perform
    catalog = DMI::Catalog.new
    variants = Spree::Variant.where(track_inventory: true)
    variants.each_slice(20) do |variant_group|      
      catalog.request_availability(variant_group)
    end
  end
end