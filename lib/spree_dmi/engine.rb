module SpreeDmi
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_dmi'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.dmi.preferences", :before => :load_config_initializers do |app|
      Spree::AppConfiguration.class_eval do
        preference :dmi_sender_id, :string
        preference :dmi_receiver_id, :string
        preference :dmi_catalog_zipcode, :string
        preference :dmi_include_confirmation_email, :boolean, default: false
        preference :dmi_capture_on_ship, :boolean, default: false
      end
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
