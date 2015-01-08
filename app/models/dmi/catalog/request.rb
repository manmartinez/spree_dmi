class DMI::Catalog::Request < DMI::Request

  attr_accessor :variants, :request_availability, :request_price

  def initialize(variants, request_availability: false, request_price: false)
    self.variants = variants
    self.request_availability = request_availability
    self.request_price = request_price
  end

  protected 

  def namespaces
    {
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
      'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
      'xmlns:dmi' => 'http://portal.suppliesnet.net',
      'xmlns' => 'http://portal.suppliesnet.net'
    }
  end

  def soap_body(xml)
    xml.RequestInfo do 
      xml.InputRequestNode do 
        items_xml(xml)
      end
    end
  end

  def items_xml(xml)
    xml['dmi'].ItemInformation(item_information_attributes) do 
      xml['dmi'].ZipCode Spree::Config.dmi_catalog_zipcode unless Spree::Config.dmi_catalog_zipcode.nil?
      xml['dmi'].PartnerISA Spree::Config.dmi_sender_id
      xml['dmi'].Items do 
        variants.each do |variant|
          xml['dmi'].Item("OEMNumber" => variant.sku)
        end
      end
    end
  end

  def item_information_attributes
    attributes = {}
    attributes['GetPrice'] = request_price ? '1' : '0'
    attributes['GetAvailability'] = request_availability ? '1' : '0'
    attributes
  end
end
