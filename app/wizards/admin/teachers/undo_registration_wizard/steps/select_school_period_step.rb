module Admin::Teachers::UndoRegistrationWizard::Steps
  class SelectSchoolPeriodStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[at_school_period_gid]

    attribute :at_school_period_gid, :string

    validate :at_school_period_belongs_to_teacher

  private

    def at_school_period_belongs_to_teacher
      return if wizard.at_school_period_from_gid(at_school_period_gid)

      errors.add(:at_school_period_gid, "Select a school period to undo for #{wizard.teacher_name}")
    end
  end
end
