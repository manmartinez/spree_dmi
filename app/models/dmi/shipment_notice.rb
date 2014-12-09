class DMI::ShipmentNotice < DMI::Base
  extend ::Savon::Model

  client wsdl: dmi_path('/ShipNotice/WebServiceShipNotice.asmx?WSDL'), log: Rails.env.development?, raise_errors: false
  operations :request_shipment_notice_xml

  # Public: Request a shipment notice using a date range.
  #
  # from  - The start date.
  # to - The end date.
  #
  # Returns true if no errors were encountered while
  # processing the response, false otherwise
  def request_with_dates(from, to)
    response = request_shipment_notice_xml(xml: DatesRequest.new(from, to).to_xml)
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
    errors.each do |error|
      process_error(error, namespaces)
    end

    shipments = document.xpath('//dmi:Shipment', namespaces)
    shipments.each do |shipment|
      process_shipment(shipment, namespaces)
    end

    errors.empty?
  end

  # Internal: Process a single <Shipment> node.
  # 
  # This updates the shipping information in the corresponding orders
  #
  # shipment  - The <Shipment> node.
  # namespaces - An array containing the namespaces of the XML response.
  #
  # Returns true if the order was updated correctly, false otherwise
  def process_shipment(shipment, namespaces)
    order_number = shipment.at_xpath('//dmi:DealerPONumber', namespaces).try(:text)
    order = Spree::Order.find_by(dmi_order_number: order_number) unless order_number.nil?
    return false if order.nil?

    shipment = order.shipments.first
    shipment.tracking = shipment.xpath('//dmi:ShipmentTrackingNumber', namespaces).map(&:text).join(',')
    shipped_at_string = shipment.at_xpath('//dmi:DateShipped', namespaces).try(:text)
    shipment.shipped_at = Date.parse(shipped_at_string) unless shipped_at_string.nil?
    shipment.ship
  end

  # Internal: Process a single <Error> node.
  # 
  # Processing an Error involves trying to update the 
  # orders involved in the error (if any) accordingly
  # and logging the error.
  #
  # error  - The <Error> node
  # namespaces - An array containing the namespaces of the XML response.
  def process_error(error, namespaces)
    order_number = error.at_xpath('//dmi:ErrorPONumber', namespaces).try(:text)
    description = error.at_xpath('//dmi:ErrorDescription', namespaces).try(:text)
    code = error.at_xpath('//dmi:ErrorNumber', namespaces).try(:text)

    unless order_number.nil?
      order = Spree::Order.find_by(dmi_order_number: order_number)
      order.update_attribute(:dmi_notes, description) unless description.nil?
    end

    # Where exactly should we log this error?
    Rails.logger.error("[ERROR] DMI::ShipmentNotice encountered an error: (#{code}) #{description}")
  end
end