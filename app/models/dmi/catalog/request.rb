class DMI::Catalog::Request < DMI::Request

  attr_accessor :items, :request_availability, :request_price

  def initialize(items, request_availability: false, request_price: false)
    self.items = items
    self.request_availability = request_availability
    self.request_price = request_price
  end

  protected 

  def soap_body(xml)
    xml.RequestInfo do 
      xml.InputRequestNode do 
        items_xml(xml)
      end
    end
  end

  def items_xml(xml)
    xml.ItemInformation(item_information_attributes) do 
      xml.ContactID Spree::Config.dmi_receiver_id
      xml.Items do 
        # items.each do |item|
          xml.Item("OEMNumber" => '841086107036', "ReferenceNumber" => '934675')
        # end
      end
    end
  end

  def item_information_attributes
    attributes = {}
    attributes['GetPrice'] = 1
    attributes['GetAvailability'] = 1
    attributes
  end
end
