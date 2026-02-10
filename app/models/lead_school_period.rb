class LeadSchoolPeriod < ApplicationRecord
  include Interval

  # Associations
  belongs_to :school
  belongs_to :appropriate_body
end
