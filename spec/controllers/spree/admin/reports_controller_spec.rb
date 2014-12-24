require 'spec_helper'

describe Spree::Admin::ReportsController, type: :controller do
  stub_authorization!

  describe 'GET #dmi_events' do 
    it "assigns the search variable" do 
      spree_get :dmi_events
      expect(assigns(:search)).to_not be nil
    end

    context "without a date range" do 
      it "populates an array with the newest events first" do 
        events = create_list(:dmi_event, 10).sort_by{ |e| e.created_at }.reverse!
        spree_get :dmi_events
        expect(assigns(:events)).to match_array(events)
      end
    end

    context "with a date range" do 
      before(:each) do 
        create_list(:dmi_event, 3, created_at: Time.now - 1.day) 
        create_list(:dmi_event, 3, created_at: Time.now + 1.day) 
      end
      
      it "populates an array with events created between the two dates" do 
        start_date = Time.now.beginning_of_month
        end_date = Time.now
        spree_get :dmi_events, q: { created_at_gt: start_date.strftime('%Y/%m/%d'), created_at_lt: end_date.strftime('%Y/%m/%d') }

        assigns(:events).each do |event|
          expect(event.created_at).to be >= start_date
          expect(event.created_at).to be <= end_date
        end
      end
    end
  end
end