class DMI::ShipmentNotice < DMI::Base
  extend ::Savon::Model

  # Public: Array containing the error codes which shouldn't be logged 
  # or considered errors
  SILENT_ERROR_CODES = [0,10]

  client wsdl: dmi_path('/ShipNotice/WebServiceShipNotice.asmx?WSDL'), log: Rails.env.development?, raise_errors: false
  operations :request_shipment_notice_xml

  # Public: Request a shipment notice using a date range.
  #
  # from  - The start date.
  # to    - The end date.
  #
  # Returns true if no errors were encountered while
  # processing the response, false otherwise
  def request_with_dates(from, to)
    response = request_shipment_notice_xml(xml: DatesRequest.new(from, to).to_xml)
    process_response(response)
  end

  # Public: Request a shipment notice using an array of orders.
  #
  # orders  - An array of Spree::Orders to request shipment status for.
  #
  # Returns true if no errors were encountered while processing 
  # the response, false otherwise
  def request_with_orders(orders)
    response = request_shipment_notice_xml(xml: OrdersRequest.new(orders).to_xml)
    process_response(response)
  end

  protected

  # Internal: Process the response from the Webservice.
  # 
  # Processing the response involves:
  # 
  # 1. Handling SOAP faults and HTTP errors
  # 2. Processing errors from the response
  # 3. Updating shipment status in the appropiate orders
  #
  # response  - The response from the web service.
  #
  # Returns true if the response was processed successfully
  def process_response(response)
    unless response.success?
      return false
    end

    document = response.doc
    namespaces = document.collect_namespaces

    errors = document.xpath('//dmi:Error', namespaces)
    no_errors = true
    errors.each do |error|
      no_errors = false if process_error(error, namespaces)
    end

    shipments = document.xpath('//dmi:Shipment', namespaces)
    shipments_updated = true
    shipments.each do |shipment|
      shipments_updated = false unless process_shipment(shipment, namespaces)
    end
    
    no_errors && shipments_updated
  end

  # Internal: Process a single <Shipment> node.
  # 
  # This updates the shipping information in the corresponding orders
  #
  # shipment   - The <Shipment> node.
  # namespaces - An array containing the namespaces of the XML response.
  #
  # Returns true if the order was updated correctly, false otherwise
  def process_shipment(shipment, namespaces)
    order_number = shipment.at_xpath('dmi:OrderNumber', namespaces).try(:text)
    order = Spree::Order.find_by(dmi_order_number: order_number) unless order_number.nil?
    return false if order.nil?

    shipped_at_string = shipment.at_xpath('dmi:DateShipped', namespaces).try(:text)
    return true if shipped_at_string.blank? # The order hasn't shipped, nothing to update
    
    spree_shipment = order.shipments.first
    spree_shipment.tracking = shipment.xpath('dmi:ShipmentTrackingNumbers/dmi:ShipmentTrackingNumber', namespaces).map(&:text).join(',')
    spree_shipment.shipped_at = Date.parse(shipped_at_string)
    spree_shipment.ship
  end

  # Internal: Process a single <Error> node.
  # 
  # Processing an Error involves trying to update the 
  # orders involved in the error (if any) accordingly
  # and logging the error.
  #
  # error      - The <Error> node
  # namespaces - An array containing the namespaces of the XML response.
  # 
  # Returns true if the error isn't silent, false otherwise
  def process_error(error, namespaces)
    code = error.at_xpath('dmi:ErrorNumber', namespaces).try(:text)
    return false if code && SILENT_ERROR_CODES.include?(code.to_i)

    order_number = error.at_xpath('dmi:ErrorOrderNumber', namespaces).try(:text)
    description = error.at_xpath('dmi:ErrorDescription', namespaces).try(:text)

    # Where exactly should we log this error?
    Rails.logger.error("[ERROR] DMI::ShipmentNotice encountered an error: (#{code}) #{description}")
    
    unless order_number.nil?
      order = Spree::Order.find_by(dmi_order_number: order_number)
      order.dmi_notes = description unless description.nil?
      order.dmi_status = 'error'
      order.save
    end
    true
  end
end