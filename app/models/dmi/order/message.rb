class DMI::Order::Message < DMI::Request

  attr_accessor :order

  def initialize(order)
    self.order = order
  end

  protected

  def soap_body(xml)
    xml.PlaceOrder do
      xml.PurchaseOrders do
        xml.PurchaseOrders(
          'TestIndicator' => test_indicator,
          'SenderID' => Spree::Config.dmi_sender_id,
          'ReceiverID' => Spree::Config.dmi_receiver_id) do
          order_xml(xml)
        end
      end
    end
  end

  def test_indicator
    Rails.env.production? ? 'P' : 'T'
  end

  def order_xml(xml)
    xml.PurchaseOrder do
      xml.OrderType 'Dealer DropShip'
      xml.DealerPONumber order.number
      xml.CustomerPONumber order.number

      xml.BillTo do
        address_xml(order.bill_address, xml)
      end

      xml.ShipTo do
        address_xml(order.ship_address, xml)
      end

      line_items_xml(xml)

      xml.EndUserConfirmationEmailAddress order.email if Spree::Config.dmi_include_confirmation_email
      additional_information_xml(xml)
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

  def line_items_xml(xml)
    xml.PurchaseOrderLines do
      order.line_items.each_with_index do |line_item, index|
        line_item_xml(line_item, index + 1, xml)
      end
    end
  end

  def line_item_xml(line_item, rank, xml)
    xml.PurchaseOrderLine do
      xml.Rank rank
      xml.OEMNumber line_item.sku
      xml.Description line_item.name
      xml.OrderQuantity line_item.quantity
      xml.UOM 'PK'
      xml.UnitPrice line_item.price
      line_item_xml_data(line_item, xml)
    end
  end

  # Internal: Additional information for the order.
  #
  # Override this method to include additional information
  # of the order when sending it to DMI.
  #
  # xml - A Nokogiri::Builder instance
  #
  # Example:
  #
  #   # In /app/models/dmi/order/message_decorator.rb
  #   DMI::Order::Message.class_eval do
  #     def additional_information_xml(xml)
  #       # Add additional information XML here using
  #       # the xml parameter
  #       xml.AdditionalInformation do
  #         xml.Company 'Railsdog'
  #         xml.CostCenter 'CA'
  #       end
  #     end
  #   end
  #
  # Returns nothing.
  def additional_information_xml(xml)

  end

  # Internal: Additional information for the line_item.
  #
  # Override this method to include additional XML
  # of a line item order when sending it to DMI.
  #
  # line_item - A Spree::LineItem
  # xml - A Nokogiri::Builder instance
  #
  # Example:
  #
  #   # In /app/models/dmi/order/message_decorator.rb
  #   DMI::Order::Message.class_eval do
  #     def line_xml_data(line_item, xml)
  #       # Add additional information under <LineXMLData>
  #       xml.LineXMLData do
  #         xml.Style line_item.style
  #         xml.Color line_item.color
  #       end
  #     end
  #   end
  #
  # Returns nothing.
  def line_item_xml_data(line_item, xml)

  end

end
