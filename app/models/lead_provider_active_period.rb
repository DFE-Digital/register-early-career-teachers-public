class LeadProviderActivePeriod < ApplicationRecord
  belongs_to :lead_provider
  belongs_to :registration_period
  has_many :delivery_partnerships, class_name: "LeadProviderDeliveryPartnership"
  has_many :expressions_of_interest, class_name: "TrainingPeriod", inverse_of: :expression_of_interest

  validates :lead_provider, presence: true
  validates :registration_period, presence: true
end
