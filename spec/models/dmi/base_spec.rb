require 'spec_helper'

describe DMI::Base do
  describe '.dmi_endpoint' do
    context "on a production environment" do
      before(:each) { allow(Rails.env).to receive(:production?).and_return(true) }
      it "returns a production endpoint" do
        expect(DMI::Base.dmi_endpoint).to eq("https://portal.suppliesnet.net")
      end
    end

    context "on a non-production environtment" do
      it "returns a sandbox endpoint" do
        expect(DMI::Base.dmi_endpoint).to eq("http://devportal.suppliesnet.net")
      end
    end
  end
end
