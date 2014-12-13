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
    items.each do |item|
      process_item(item, namespaces)
    end
  end

  # Internal: Log an error.
  #
  # error      - An <Error> node.
  # namespaces - An array containing the namespaces of the XML response.
  #
  # Returns nothing
  def log_error(error, namespaces)
    code = error.at_xpath('dmi:ErrorNumber').try(:text)
    description = error.at_xpath('dmi:ErrorDescription').try(:text)
    # We probably want to log this somewhere else, say a DB table
    Rails.logger.error("[ERROR] DMI::Catalog encountered an error: (#{code}) #{description}")
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
    return false if variant.nil?
    count_per_location = item.xpath('dmi:Availability')
    count_per_location.each do |count_on_location|
      update_count_at_location(variant, count_on_location)
    end
  end

  # Internal: Make sure stock for a variant matches Spree's stock
  # at a given stock location.
  #
  # variant           - A Spree::Variant.
  # count_on_location - A single <Availability> node from the XML response
  #
  # Returns false if any errors where encountered, true otherwise
  def update_count_at_location(variant, count_on_location)
    location_code = count_on_location.attr('DC')
    stock_location = Spree::StockLocation.find_by(dmi_code: location_code)
    return false if stock_location.nil?

    stock_item = variant.stock_items.find_by(stock_location_id: stock_location.id)
    dmi_count = count_on_location.text.to_i

    if stock_item.count_on_hand != dmi_count
      # Alert the user that there was a discrepancy here
      stock_item.stock_movements.build(quantity: dmi_count - stock_item.count_on_hand).save
    else
      true
    end
  end
end