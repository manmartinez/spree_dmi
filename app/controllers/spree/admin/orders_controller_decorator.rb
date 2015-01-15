Spree::Admin::OrdersController.class_eval do 
  before_action :load_order, only: [:retry_dmi_send]

  def retry_dmi_send
    @order.send_to_dmi

    if @order.dmi_error?
      flash[:error] = Spree.t(:retry_dmi_send_error)
    else
      flash[:success] = Spree.t(:retry_dmi_send_success)
    end  
    redirect_to spree.admin_orders_url
  end
end