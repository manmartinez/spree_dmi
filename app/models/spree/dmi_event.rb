class Spree::DmiEvent < Spree::Base

  validates :event_type, :description, presence: true
  validates :event_type, inclusion: { in: %w(info error success warning) }

  scope :info, ->{ where(event_type: :info) }
  scope :error, ->{ where(event_type: :error) }
  scope :success, ->{ where(event_type: :success) }
  scope :warning, ->{ where(event_type: :warning) }

  def self.build_warning(description)
    self.new(event_type: 'warning', description: description)
  end

  def self.build_info(description)
    self.new(event_type: 'info', description: description)
  end

  def self.build_error(description)
    self.new(event_type: 'error', description: description)
  end

  def self.build_success(description)
    self.new(event_type: 'success', description: description)
  end

  def self.create_warning(description)
    event = self.build_warning(description)
    event.save
    event
  end

  def self.create_info(description)
    event = self.build_info(description)
    event.save
    event
  end

  def self.create_error(description)
    event = self.build_error(description)
    event.save
    event
  end

  def self.create_success(description)
    event = self.build_success(description)
    event.save
    event
  end

end
