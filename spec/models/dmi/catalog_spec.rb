require 'spec_helper'
require 'savon/mock/spec_helper'

describe DMI::Catalog do
  include Savon::SpecHelper 

  describe '#request_availability' do 

    before(:each) { savon.mock! }
    after(:each) { savon.unmock! }
    subject(:catalog) { DMI::Catalog.new }

    context "with registered SKU numbers" do 
      let(:state) { create(:state, name: 'California', abbr: 'CA') }
      let(:variants) do 
        %w(841086107043 841086107036).map do |sku|
          create(:variant, sku: sku)
        end
      end

      before(:each) do
        @stock_location = create(:stock_location, state: state)
        response = File.read("spec/fixtures/catalog/items_availability.xml")
        savon.expects(:request_info).with(message: :any).returns(response)
      end

      context "when count on hand doesn't match DMI's" do

        it "updates spree stock" do
          catalog.request_availability(variants)
          variants.each do |variant|
            expect(variant.stock_items.first.count_on_hand).to eq 10
          end
        end

        it "logs the discrepancy" do 
          expect{
            catalog.request_availability(variants)  
          }.to change(Spree::DmiEvent, :count).by(variants.size)
        end

        it "returns true" do 
          expect(catalog.request_availability(variants)).to be true
        end
      end

      context "when count on hand matches DMI's" do
        before(:each) do 
          variants.each do |variant|
            variant.stock_items.find_by(stock_location_id: @stock_location.id).set_count_on_hand(10)
          end
        end

        it "returns true" do
          expect(catalog.request_availability(variants)).to be true
        end
      end


      
    end

    context "with unregistered SKU numbers" do 
      let(:variants) do 
        %w(ROR-00008 ROR-00009 ROR-00010).map do |sku|
          create(:variant, sku: sku)
        end
      end

      before(:each) do
        response = File.read("spec/fixtures/catalog/items_not_found.xml")
        savon.expects(:request_info).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(catalog.request_availability(variants)).to be false
      end

      it "logs the error" do 
        expect{
          catalog.request_availability(variants)
        }.to change(Spree::DmiEvent, :count).by(variants.size)
      end
    end

    context "when something goes terribly wrong" do 
      let(:variants) do 
        %w(ROR-00008 ROR-00009 ROR-00010).map do |sku|
          create(:variant, sku: sku)
        end
      end

      before(:each) do 
        soap_fault = File.read("spec/fixtures/shared/soap_fault.xml")
        response = { code: 500, headers: {}, body: soap_fault }
        savon.expects(:request_info).with(message: :any).returns(response)
      end

      it "returns false" do 
        expect(catalog.request_availability(variants)).to be false
      end

      # it "logs the error" do 
        
      # end

    end
  end
end
