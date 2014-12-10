class DMI::ShipmentNotice::OrdersRequest
  attr_accessor :orders

  def initialize(orders)
    self.orders = orders
  end

  def builder
    return @builder if defined? @builder
    @builder = Nokogiri::XML::Builder.new do |xml|
      xml['soap'].Envelope(namespaces) do
        xml['soap'].Body do
          xml.RequestShipmentNoticeXML do 
            xml.ShipNoticeRequestNode do 
              orders_xml(xml)
            end
          end
        end
      end
    end
  end

  def to_xml
    builder.to_xml
  end

  protected

  def orders_xml(xml)
    xml.ShipNoticeRequest do
      xml.RequesterISA Spree::Config.dmi_sender_id
      orders.each do |order|
        xml.Order do 
          xml.OrderNumber order.dmi_order_number
        end
      end
    end
  end

  def namespaces
    {
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
      'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
      'xmlns' => 'http://portal.suppliesnet.net'
    }
  end
end
