class DMI::Shipper
  extend ActiveModel::Naming

  attr_accessor :order
  attr_reader :errors

  # Public: Create a new instance of DMI::Shipper.
  #
  # order  - A Spree::Order object
  #
  # Returns a new instance of DMI::Shipper
  def initialize(order)
    self.order = order
    @errors = ActiveModel::Errors.new(self)
  end

  # Public: Ship a the Spree order.
  #
  # If Spree::Config.dmi_capture_on_ship is set
  # to true this will capture all pending payments
  # and then call #ship on the first shipment of
  # the order
  # 
  # If any errors occur they'll be logged using
  # DMI::Events and the order's dmi_status and dmi_notes
  # will be updated accordingly
  #
  #
  # Returns true if shipping the order was successful, false otherwise
  def ship(tracking_number, shipped_at)
    if Spree::Config.dmi_capture_on_ship
      success = capture_pending_payments && update_shipments(tracking_number, shipped_at)
    else
      success = update_shipments(tracking_number, shipped_at)
    end

    log_shipping_errors unless success
    success
  end

  # Internal: This method needs to be implemented in order
  # to be able to call errors.full_messages
  #
  # Returns the humanized version of the attribute
  def self.human_attribute_name(attr, options = {})
    attr
  end

  protected

    # Internal: Log any shipping errors.
    #
    # Returns nothing
    def log_shipping_errors
      humanized_errors = errors.full_messages.to_sentence
      Spree::DmiEvent.create_error("Couldn't ship order #{order.number}: #{humanized_errors}")
      order.dmi_notes = humanized_errors
      order.dmi_status = 'error'
      order.save
    end

    # Internal: Ship the order's shipments.
    # 
    # This method will also update the tracking_number and
    # shipped_at attributes on the shipments
    # 
    # tracking_number - The tracking number for the shipment
    # shipped_at      - The date the order was shipped
    #
    # Returns true if shipping was successful, false otherwise
    def update_shipments(tracking_number, shipped_at)
      shipment = order.shipments.first

      shipment.shipped_at = shipped_at
      shipment.tracking = tracking_number
      success = shipment.ship

      copy_errors(shipment) unless success
      success
    end

    # Internal: Captures all pending payments on the order.
    #
    # Returns true if all payments were captured successfully,
    # false otherwise
    def capture_pending_payments
      success = true
      order.payments.pending.each do |payment|
        unless payment.capture!
          copy_errors(payment)
          success = false
        end
      end
      success
    end

    # Internal: Copy errors from another object onto the
    # instance's error
    #
    # Returns nothing
    def copy_errors(source)
      source.errors.each do |key, error|
        self.errors.add(key, error)
      end
    end

end