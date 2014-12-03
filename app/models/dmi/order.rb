class DMI::Order
  extend ::Savon::Model

  client wsdl: 'http://devportal.suppliesnet.net/PurchaseOrders/PurchaseOrder.asmx?WSDL', log: true
  operations :place_order

  def self.place(order)
    response = self.place_order(message: Message.new(order))
    document = response.doc
    fail_misserably!
  end
end