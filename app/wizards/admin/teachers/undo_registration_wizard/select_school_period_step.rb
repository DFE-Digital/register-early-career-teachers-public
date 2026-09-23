module Admin
  module Teachers
    module UndoRegistrationWizard
      class SelectSchoolPeriodStep < Step
        attribute :school_period_gid, :string

        validate :school_period_belongs_to_teacher

        def self.permitted_params = %i[school_period_gid]

        def previous_step = :start
        def next_step = :confirm

      private

        def persist
          store.school_period_gid = step_params["school_period_gid"] || school_period_gid
        end

        def school_period_belongs_to_teacher
          return if wizard.school_period_from_gid(school_period_gid)

          errors.add(:school_period_gid, "Select a school period to undo for #{wizard.teacher_name}")
        end
      end
    end
  end
end
