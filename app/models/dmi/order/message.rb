class DMI::Order::Message

  attr_accessor :order, :builder

  def initialize(order)
    self.order = order
    make_builder
  end

  def make_builder
    self.builder = Nokogiri::XML::Builder.new do |xml|
      xml['dmi'].PurchaseOrders(
        'xmlns:dmi' => 'http://portal.suppliesnet.net', 
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 
        'TestIndicator' => 'T', 
        'SenderID' => '5wP6q0xXfM89f6pD',
        'ReceiverID' => '064632888') {
        xml['dmi'].PurchaseOrder {
          xml['dmi'].OrderType 'Stock Order'
          xml['dmi'].BillTo {
            address_xml(order.ship_address, xml)
          }
          xml['dmi'].ShipTo {
            address_xml(order.bill_address, xml)
          }
          xml['dmi'].PurchaseOrderLines {
            order.line_items.each_with_index do |line_item, index|
              line_item_xml(line_item, index + 1, xml)
            end
          }
          xml['dmi'].EndUserConfirmationEmailAddress order.email
        }
      }
    end
  end

  def to_s
    builder.doc.root.to_xml
  end

  def address_xml(address, xml)
    xml['dmi'].Name address.full_name
    xml['dmi'].Address1 address.address1
    unless address.address2.blank?
      xml['dmi'].Address2 address.address2
    end
    xml['dmi'].City address.city
    xml['dmi'].State address.state_text.upcase
    xml['dmi'].ZipCode address.zipcode
    xml['dmi'].CountryCode address.country.try(:iso)
    xml['dmi'].Contact {
      xml['dmi'].ContactName address.full_name
      xml['dmi'].ContactMethod 'Phone'
      xml['dmi'].ContactAddress address.phone
    }
  end

  def line_item_xml(line_item, rank, xml)
    xml['dmi'].PurchaseOrderLine {
      xml['dmi'].Rank rank
      xml['dmi'].OEMNumber line_item.sku
      xml['dmi'].Description line_item.description
      xml['dmi'].OrderQuantity line_item.quantity
      xml['dmi'].UOM 'PK'
      xml['dmi'].UnitPrice line_item.price
    }
  end

end
