class Statement < ApplicationRecord
  belongs_to :active_lead_provider
  has_many :adjustments
end
