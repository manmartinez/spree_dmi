class DMI::Base
  # Public: Returns the endpoint for DMI according to the current environment
  #
  # Returns the endpoint for DMI
  def self.dmi_endpoint
    if Rails.env.production? 
      'https://portal.suppliesnet.net'
    else
      'http://devportal.suppliesnet.net'
    end
  end

  # Public: Returns a full URL pointing to DMI by prepending
  # dmi_endpoint to path
  # 
  # path - The path to append to self.dmi_endpoint
  # 
  # Returns a full URL to DMI
  def self.dmi_path(path)
    # FIXME: There has to be a better way to do this
    "#{dmi_endpoint}#{path}"
  end
end