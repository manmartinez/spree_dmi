class DMI::Order < DMI::Base
  extend ::Savon::Model

  client wsdl: dmi_path('/PurchaseOrders/PurchaseOrder.asmx?WSDL'), log: Rails.env.development?, raise_errors: false
  operations :place_order

  # Internal: Place an order in DMI. 
  # 
  # This method will call DMI's PurchaseOrder SOAP action and 
  # update the order accordingly
  # 
  # order - The Spree::Order object that wants to be placed in DMI
  # 
  # Returns true if there where no errors reported by DMI, false otherwise
  def self.place(order)
    response = self.place_order(xml: Message.new(order).to_xml)
    
    unless response.success?
      order.update_attribute(:dmi_status, 'error')
      return false
    end

    document = response.doc
    namespaces = document.collect_namespaces
    errors = document.xpath('//dmi:Error', namespaces)
    attributes = {}

    if errors.any?
      attributes[:dmi_status] = 'error'
      attributes[:dmi_notes] = errors.xpath('//dmi:ErrorDescription', namespaces).map { |n| n.text }.join(';')
    else
      attributes[:dmi_status] = document.at_xpath('//dmi:OrderStatus', namespaces).try(:text)
      attributes[:dmi_order_number] = document.at_xpath('//dmi:OrderNumber', namespaces).try(:text)
    end

    order.update_attributes(attributes)
    errors.empty?
  end
end