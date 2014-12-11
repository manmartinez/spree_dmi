class DMI::Request

  def to_xml
    builder.to_xml
  end

  protected

  def builder
    return @builder if defined? @builder
    @builder = Nokogiri::XML::Builder.new do |xml|
      soap_envelope(xml) do
        soap_body(xml)
      end
    end
  end

  def soap_envelope(xml)
    xml['soap'].Envelope(namespaces) do
      xml['soap'].Body do
        yield
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