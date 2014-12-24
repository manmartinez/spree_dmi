Spree::Admin::ReportsController.class_eval do 
  add_available_report! :dmi_events

  def dmi_events
    params[:q] = {} unless params[:q]
    set_date_params

    @search = Spree::DmiEvent.search(params[:q])
    @search.sorts = 'created_at desc' if @search.sorts.empty?
    @events = @search.result.page(params[:page]).per(50)
  end

  protected

    def set_date_params
      if params[:q][:created_at_gt].blank?
        params[:q][:created_at_gt] = Time.zone.now.beginning_of_month
      else
        params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
      end

      unless params[:q][:created_at_lt].blank?
        params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
      end
    end
end