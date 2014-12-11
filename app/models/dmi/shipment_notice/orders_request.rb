class DMI::ShipmentNotice::OrdersRequest < DMI::Request
  attr_accessor :orders

  def initialize(orders)
    self.orders = orders
  end

  protected

  def soap_body(xml)
    xml.RequestShipmentNoticeXML do 
      xml.ShipNoticeRequestNode do 
        orders_xml(xml)
      end
    end
  end

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

end
