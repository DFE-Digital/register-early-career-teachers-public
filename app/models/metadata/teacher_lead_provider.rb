module Metadata
  class TeacherLeadProvider < Metadata::Base
    self.table_name = :metadata_teachers_lead_providers

    belongs_to :teacher
    belongs_to :lead_provider

    belongs_to :latest_ect_training_period, optional: true, class_name: "TrainingPeriod"
    belongs_to :latest_mentor_training_period, optional: true, class_name: "TrainingPeriod"
    belongs_to :latest_ect_contract_period, optional: true, class_name: "ContractPeriod", foreign_key: :latest_ect_contract_period_year
    belongs_to :latest_mentor_contract_period, optional: true, class_name: "ContractPeriod", foreign_key: :latest_mentor_contract_period_year

    validates :teacher, presence: true
    validates :lead_provider, presence: true
    validate :latest_ect_training_period_contract_period_consistency
    validate :latest_mentor_training_period_contract_period_consistency

  private

    def latest_ect_training_period_contract_period_consistency
      if latest_ect_training_period.present? ^ latest_ect_contract_period.present?
        errors.add(:base, "Latest ECT training period and contract period must both be set or both be nil")
      end
    end

    def latest_mentor_training_period_contract_period_consistency
      if latest_mentor_training_period.present? ^ latest_mentor_contract_period.present?
        errors.add(:base, "Latest mentor training period and contract period must both be set or both be nil")
      end
    end
  end
end
