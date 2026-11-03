module Admin::Teachers::UndoRegistrationWizard
  class StateStore
    include DfE::Wizard::StateStore

    attr_reader :teacher, :author

    def initialize(teacher:, author:, **)
      super(**)
      @teacher = teacher
      @author = author
    end

    def multiple_school_periods? = at_school_periods.many?

    def registration_undone?
      read[:registration_undone] == true
    end

    def journey_available?
      return false if at_school_periods.empty?
      return true unless at_school_period

      undo_registration.undoable?
    end

    def teacher_name
      ::Teachers::Name.new(teacher).full_name
    end

    def ect_at_school_periods
      @ect_at_school_periods ||= teacher.ect_at_school_periods
        .includes(:school, :school_reported_appropriate_body)
        .order(started_on: :desc)
    end

    def mentor_at_school_periods
      @mentor_at_school_periods ||= teacher.mentor_at_school_periods
        .includes(:school)
        .order(started_on: :desc)
    end

    def at_school_periods
      @at_school_periods ||= ect_at_school_periods + mentor_at_school_periods
    end

    def at_school_period
      return selected_at_school_period if selected_at_school_period

      at_school_periods.first if at_school_periods.one?
    end

    def at_school_period_from_gid(at_school_period_gid)
      at_school_periods.find { |at_school_period| at_school_period.to_global_id.to_s == at_school_period_gid }
    end

    def periods_will_be_closed?
      return @periods_will_be_closed if defined?(@periods_will_be_closed)

      @periods_will_be_closed = undo_registration.periods_will_be_closed?
    end

    delegate :finish_date_for, to: :undo_registration

    def undo_registration!(
      expected_action:,
      expected_training_period_ids:,
      expected_mentorship_period_ids:,
      expected_at_school_period_gid:
    )
      undo_registration.undo!(
        expected_action:,
        expected_training_period_ids:,
        expected_mentorship_period_ids:,
        expected_at_school_period_gid:
      )
    end

    def undo_action = self[:undo_action]

    def affected_training_periods
      @affected_training_periods ||= periods_affected(
        at_school_period.training_periods.includes(
          :schedule,
          :school_partnership,
          :lead_provider,
          :delivery_partner,
          :contract_period,
          :expression_of_interest_lead_provider,
          :expression_of_interest_contract_period
        )
      )
    end

    def affected_mentorship_periods
      @affected_mentorship_periods ||= periods_affected(
        at_school_period.mentorship_periods.includes(mentor: :teacher, mentee: :teacher)
      )
    end

  private

    def undo_registration
      @undo_registration ||= ::Teachers::UndoRegistration.new(
        author:,
        at_school_period:,
        reason: :registered_in_error
      )
    end

    def selected_at_school_period
      @selected_at_school_period ||= at_school_period_from_gid(self[:at_school_period_gid])
    end

    def periods_affected(periods)
      periods_will_be_closed? ? periods.unfinished : periods
    end
  end
end
