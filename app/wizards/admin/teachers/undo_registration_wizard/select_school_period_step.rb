module Admin
  module Teachers
    module UndoRegistrationWizard
      class SelectSchoolPeriodStep < Step
        attribute :school_period, :string

        validate :school_period_belongs_to_teacher

        def self.permitted_params = %i[school_period]

        def previous_step = :start
        def next_step = :confirm

      private

        def persist
          store.school_period = step_params["school_period"] || school_period
        end

        def school_period_belongs_to_teacher
          return if wizard.school_period_from_selection(school_period)

          errors.add(:school_period, "Select a school period to undo for #{wizard.teacher_name}")
        end
      end
    end
  end
end
