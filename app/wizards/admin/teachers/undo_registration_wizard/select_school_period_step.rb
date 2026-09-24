module Admin
  module Teachers
    module UndoRegistrationWizard
      class SelectSchoolPeriodStep < Step
        attribute :at_school_period_gid, :string

        validate :at_school_period_belongs_to_teacher

        def self.permitted_params = %i[at_school_period_gid]

        def previous_step = :start
        def next_step = :confirm

      private

        def persist
          store.at_school_period_gid = step_params["at_school_period_gid"] || at_school_period_gid
        end

        def at_school_period_belongs_to_teacher
          return if wizard.at_school_period_from_gid(at_school_period_gid)

          errors.add(:at_school_period_gid, "Select a school period to undo for #{wizard.teacher_name}")
        end
      end
    end
  end
end
