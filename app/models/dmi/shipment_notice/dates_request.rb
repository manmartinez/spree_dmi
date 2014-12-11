class DMI::ShipmentNotice::DatesRequest < DMI::Request
  attr_accessor :start_date, :end_date

  def initialize(start_date, end_date)
    self.start_date = start_date
    self.end_date = end_date
  end

  def builder
    return @builder if defined? @builder
    @builder = Nokogiri::XML::Builder.new do |xml|
      soap_envelope(xml) do
        xml.RequestShipmentNoticeXML do 
          xml.ShipNoticeRequestNode do 
            date_range_xml(xml)
          end
        end
      end
    end
  end

  def to_xml
    builder.to_xml
  end

  protected

  def date_range_xml(xml)
    xml.ShipNoticeRequest do
      xml.RequesterISA Spree::Config.dmi_sender_id
      xml.ShipDateRange do 
        xml.ShipDateFrom start_date.strftime('%Y-%m-%d')
        xml.ShipDateTo end_date.strftime('%Y-%m-%d')
      end
    end
  end
end
