class PupilPremium < ApplicationRecord
  self.table_name = "pupil_premiums"

  belongs_to :school,
             foreign_key: :school_urn,
             primary_key: :urn

  belongs_to :contract_period,
             foreign_key: :contract_period_year,
             primary_key: :year

  validates :school, presence: true
  validates :contract_period, presence: true
  validates :pupil_premium_uplift, inclusion: { in: [true, false] }
  validates :sparsity_uplift, inclusion: { in: [true, false] }
end
