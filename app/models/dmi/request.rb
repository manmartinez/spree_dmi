class DMI::Request

  protected

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