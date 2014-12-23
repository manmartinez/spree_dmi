require 'spec_helper'

describe Spree::DmiEvent, type: :model do
  it { should validate_presence_of(:event_type) }
  it { should validate_presence_of(:description) }
  it { should validate_inclusion_of(:event_type).in_array( %w(error info success) ) }
end
