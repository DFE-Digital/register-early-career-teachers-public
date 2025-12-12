module Declarations
  class MentorCompletion
    attr_reader :author, :declaration

    def initialize(author:, declaration:)
      @author = author
      @declaration = declaration
    end

    def perform
      return false unless mentor_completion_event?

      ActiveRecord::Base.transaction do
        if latest_completed_declaration.billable_or_changeable?
          mentor_completed_training!
          finish_training_period!
        else
          mentor_not_completed_training!
          create_training_period! unless latest_training_period.ongoing_today?
        end

        record_completion_change_event!
      end
    end

  private

    delegate :training_period, to: :declaration
    delegate :trainee, to: :training_period
    delegate :teacher, to: :trainee

    def mentor_completion_event?
      training_period.for_mentor? && declaration.declaration_type_completed?
    end

    def create_training_period!
      period = latest_training_period.mentor_at_school_period

      TrainingPeriods::Create.provider_led(
        period:,
        started_on: latest_training_period.finished_on,
        finished_on: period.finished_on,
        school_partnership: latest_training_period.school_partnership,
        expression_of_interest: nil,
        schedule: latest_training_period.schedule,
        author:
      ).call
    end

    def finish_training_period!
      TrainingPeriods::Finish.mentor_training(
        training_period: latest_training_period,
        mentor_at_school_period: latest_training_period.mentor_at_school_period,
        finished_on:,
        author:
      ).finish!
    end

    def finished_on
      if declaration.declaration_date > latest_training_period.started_on
        declaration.declaration_date
      else
        latest_training_period.started_on + 1.day
      end
    end

    def latest_training_period
      @latest_training_period ||= metadata.latest_mentor_training_period
    end

    def metadata
      @metadata ||= teacher.lead_provider_metadata.find_by(lead_provider_id: training_period.lead_provider.id)
    end

    def mentor_completed_training!
      teacher.update!(
        mentor_became_ineligible_for_funding_on: latest_completed_declaration.declaration_date,
        mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
      )
    end

    def mentor_not_completed_training!
      teacher.update!(
        mentor_became_ineligible_for_funding_on: nil,
        mentor_became_ineligible_for_funding_reason: nil
      )
    end

    def latest_completed_declaration
      @latest_completed_declaration ||= teacher
        .mentor_declarations
        .declaration_type_completed
        .order(declaration_date: :desc)
        .first!
    end

    def record_completion_change_event!
      return unless teacher.saved_changes?

      Events::Record.record_mentor_completion_status_change!(
        author:,
        teacher:,
        training_period:,
        declaration:,
        modifications: teacher.saved_changes
      )
    end
  end
end
