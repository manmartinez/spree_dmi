class DMI::Catalog < DMI::Base
  extend ::Savon::Model

  client wsdl: dmi_path('/CatalogRequest/CatalogRequest.asmx?WSDL'), log: Rails.env.development?, raise_errors: false
  operations :request_info

  # Public: Request availability for a series of Spree::Variants.
  #
  # variants  - An array of Spree::Variants
  #
  # Returns false if any errors where encountered, true otherwise
  def request_availability(variants)
    response = request_info(xml: Request.new(variants, request_availability: true).to_xml)
    process_response(response)
  end

  protected

  # Internal: Process the response from the Webservice.
  # 
  # Processing the response involves:
  # 
  # 1. Handling SOAP faults and HTTP errors
  # 2. Processing errors from the response
  # 3. Updating stock for appropiate variants
  #
  # response  - The response from the web service.
  #
  # Returns true if the response was processed successfully
  def process_response(response)
    return false unless response.success?

    document = response.doc
    namespaces = document.collect_namespaces

    errors = document.xpath('//dmi:Error', namespaces)
    errors.each do |error| 
      log_error(error, namespaces) 
    end
    return false if errors.any?

    items = document.xpath('//dmi:Item', namespaces)
    items_processed = true
    items.each do |item|
      items_processed = false unless process_item(item, namespaces)
    end
    items_processed
  end

  # Internal: Log an error.
  #
  # error      - An <Error> node.
  # namespaces - An array containing the namespaces of the XML response.
  #
  # Returns nothing
  def log_error(error, namespaces)
    code = error.at_xpath('dmi:ErrorNumber', namespaces).try(:text)
    description = error.at_xpath('dmi:ErrorDescription', namespaces).try(:text)
    
    Spree::DmiEvent.create_error("An error ocurred while syncing stock: (#{code}) #{description}")
  end

  # Internal: Process a single <Item> node.
  # 
  # Processing an item involves ensuring DMI's stock matches Spree's stock
  # for this item, in case stock doesn't match the proper Spree::StockMovements
  # will be generated
  #
  # item       - The <Item> node.
  # namespaces - An array containing the namespaces of the XML response
  #
  # Returns true if the item was processed correctly, false otherwise
  def process_item(item, namespaces)
    variant = Spree::Variant.find_by(sku: item.attr('OEMNumber'))

    if variant.nil?
      Spree::DmiEvent.create_error("The following SKU is not registered in Spree: #{item.attr('OEMNumber')}")
      return false
    end

    count_per_location = item.xpath('dmi:Availability', namespaces)
    stock_updated = true
    count_per_location.each do |count_on_location|
      stock_updated = false unless update_count_at_location(variant, count_on_location)
    end
    stock_updated
  end

  # Internal: Make sure stock for a variant matches Spree's stock
  # at a given stock location.
  #
  # variant           - A Spree::Variant.
  # count_on_location - A single <Availability> node from the XML response
  #
  # Returns false if any errors where encountered, true otherwise
  def update_count_at_location(variant, count_on_location)
    dmi_count = count_on_location.text.to_i

    if dmi_count < 0
      Spree::DmiEvent.create_error("The following SKU is not registered in DMI: #{variant.sku}")
      return false
    end

    location_code = count_on_location.attr('DC')
    stock_location = find_stock_location(location_code)
    return false if stock_location.nil?

    sync_stock(variant, stock_location, dmi_count)
  end

  # Internal: Finds a matching stock location on Spree or Logs an error if it's missing.
  #
  # location_code  - The location code for the stock location sent by DMI
  #
  # Returns the Spree::StockLocation or nil
  def find_stock_location(location_code)
    stock_location = Spree::StockLocation.joins(:state).find_by(Spree::State.table_name => { abbr: location_code })
    if stock_location.nil?
      Spree::DmiEvent.create_error("Spree couldn't find a matching stock location for code: #{location_code}")
    end
    stock_location
  end

  # Internal: Sync the stock count between Spree and DMI for a single Variant
  #
  # variant         - The Spree::Variant to sync stock items for
  # stock_location  - The stock location to sync
  # dmi_count       - Count on hand for the variant on DMI
  #
  # Returns the true if the stock was synced successfully, false otherwise
  def sync_stock(variant, stock_location, dmi_count)
    stock_item = variant.stock_items.find_by(stock_location_id: stock_location.id)

    if stock_item.count_on_hand != dmi_count
      Spree::DmiEvent.create_warning("Expected #{stock_item.count_on_hand} items on hand for sku:#{variant.sku} on stock location: #{stock_location.name}, got: #{dmi_count}")
      stock_item.stock_movements.build(quantity: dmi_count - stock_item.count_on_hand).save
    else
      true
    end
  end
end
