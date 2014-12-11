class DMI::Order::Message < DMI::Request

  attr_accessor :order

  def initialize(order)
    self.order = order
  end

  def to_xml
    builder.to_xml
  end

  def builder
    return @builder if defined? @builder
    @builder = Nokogiri::XML::Builder.new do |xml|
      soap_envelope(xml) do
        xml.PlaceOrder do
          xml.PurchaseOrders do
            xml.PurchaseOrders(
              'TestIndicator' => 'T', 
              'SenderID' => Spree::Config.dmi_sender_id,
              'ReceiverID' => Spree::Config.dmi_receiver_id) do
              order_xml(xml)
            end  
          end
        end
      end
    end
  end

  protected

  def order_xml(xml)
    xml.PurchaseOrder do
      xml.OrderType 'Stock Order'
      xml.BillTo do
        address_xml(order.bill_address, xml)
      end
      xml.ShipTo do
        address_xml(order.ship_address, xml)
      end
      xml.PurchaseOrderLines do
        order.line_items.each_with_index do |line_item, index|
          line_item_xml(line_item, index + 1, xml)
        end
      end
      xml.EndUserConfirmationEmailAddress order.email
    end
  end

  def address_xml(address, xml)
    xml.Name address.full_name
    xml.Address1 address.address1
    unless address.address2.blank?
      xml.Address2 address.address2
    end
    xml.City address.city
    xml.State address.state_text.upcase
    xml.ZipCode address.zipcode
    xml.CountryCode address.country.try(:iso)
  end

  def line_item_xml(line_item, rank, xml)
    xml.PurchaseOrderLine do
      xml.Rank rank
      xml.OEMNumber line_item.sku
      xml.Description line_item.name
      xml.OrderQuantity line_item.quantity
      xml.UOM 'PK'
      xml.UnitPrice line_item.price
    end
  end

end
