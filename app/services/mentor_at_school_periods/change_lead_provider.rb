module MentorAtSchoolPeriods
  class ChangeLeadProvider
    class LeadProviderNotChangedError < StandardError; end

    attr_reader :mentor_at_school_period,
                :lead_provider,
                :author

    include TrainingPeriodSources

    def initialize(mentor_at_school_period:, lead_provider:, author:)
      @mentor_at_school_period = mentor_at_school_period
      @lead_provider = lead_provider
      @author = author
    end

    def call
      raise LeadProviderNotChangedError unless lead_provider_changed?

      ActiveRecord::Base.transaction do
        if date_of_transition.future? || training_period_not_confirmed
          training_period.destroy!
        else
          finish_training_period!
        end

        create_training_period!
        record_lead_provider_updated_event!
      end
    end

  private

    def finish_training_period!
      return if training_period.blank?

      TrainingPeriods::Finish.mentor_training(
        training_period:,
        mentor_at_school_period:,
        finished_on: Date.current,
        author:
      ).finish!
    end

    def create_training_period!
      TrainingPeriods::Create.provider_led(
        period: mentor_at_school_period,
        started_on: date_of_transition,
        school_partnership:,
        expression_of_interest:
      ).call
    end

    def record_lead_provider_updated_event!
      ::Events::Record.record_mentor_lead_provider_updated_event!(
        old_lead_provider_name: old_lead_provider.name,
        new_lead_provider_name: lead_provider.name,
        author:,
        mentor_at_school_period:,
        school:,
        teacher:,
        happened_at: date_of_transition
      )
    end

    def expression_of_interest
      @expression_of_interest ||= create_expression_of_interest
    end

    def create_expression_of_interest
      ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period:)
    end

    def teacher
      mentor_at_school_period.teacher
    end

    def school
      mentor_at_school_period.school
    end

    def school_partnership
      earliest_matching_school_partnership
    end

    def date_of_transition
      [mentor_at_school_period.started_on, Date.current].max
    end

    alias_method :started_on, :date_of_transition

    def training_period
      mentor_at_school_period.current_or_next_training_period
    end

    def training_period_not_confirmed
      training_period && training_period.school_partnership.blank?
    end

    def lead_provider_changed?
      old_lead_provider != lead_provider
    end

    def latest_registration_choice
      MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: teacher.trn)
    end

    def old_lead_provider
      @old_lead_provider ||= latest_registration_choice&.lead_provider
    end
  end
end
