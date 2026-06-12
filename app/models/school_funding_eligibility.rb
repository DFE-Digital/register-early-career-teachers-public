class SchoolFundingEligibility < ApplicationRecord
  belongs_to :gias_school, class_name: "GIAS::School", foreign_key: :school_urn, primary_key: :urn, inverse_of: :school_funding_eligibilities
  belongs_to :contract_period, foreign_key: :contract_period_year, primary_key: :year

  validates :gias_school, presence: true
  validates :contract_period, presence: true
  validates :pupil_premium_uplift, inclusion: { in: [true, false] }
  validates :sparsity_uplift, inclusion: { in: [true, false] }
end
