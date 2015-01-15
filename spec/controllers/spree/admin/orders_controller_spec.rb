require 'spec_helper'
require 'savon/mock/spec_helper'

describe Spree::Admin::OrdersController, type: :controller do
  include Savon::SpecHelper 

  stub_authorization!

  before(:each) { savon.mock! }
  after(:each) { savon.unmock! }

  describe 'PATCH #retry_dmi_send' do 
    let(:order) { create(:order_with_dmi_error) }

    it "locates the right order" do 
      response = File.read("spec/fixtures/order/order_processed.xml")
      savon.expects(:place_order).with(message: :any).returns(response)
      patch :retry_dmi_send, id: order, use_route: :spree
      expect(assigns[:order]).to eq order
    end

    context "when retry is successful" do
      before(:each) do
        response = File.read("spec/fixtures/order/order_processed.xml")
        savon.expects(:place_order).with(message: :any).returns(response)
      end

      it "sets the flash in case of success" do 
        patch :retry_dmi_send, id: order, use_route: :spree
        should set_the_flash[:success]
      end

      it "should update the order's dmi_status" do 
        patch :retry_dmi_send, id: order, use_route: :spree
        expect(assigns[:order].dmi_error?).to be false
      end
    end
    
    context "when retry fails" do
      before(:each) do 
        response = File.read("spec/fixtures/order/unregistered_skus.xml")
        savon.expects(:place_order).with(message: :any).returns(response)
      end

      it "sets the flash in case of error" do 
        patch :retry_dmi_send, id: order, use_route: :spree
        should set_the_flash[:error]
      end

      it "should update the order's dmi_status" do 
        patch :retry_dmi_send, id: order, use_route: :spree
        expect(assigns[:order].dmi_error?).to be true
      end
    end
  end
end