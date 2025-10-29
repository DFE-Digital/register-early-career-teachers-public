module MentorAtSchoolPeriods
  class ChangeLeadProvider
    attr_reader :mentor_at_school_period,
                :lead_provider,
                :author

    def initialize(mentor_at_school_period:, lead_provider:, author:)
      @mentor_at_school_period = mentor_at_school_period
      @lead_provider = lead_provider
      @author = author
    end

    def call
      return false unless lead_provider_changed?

      finish_existing_at_school_periods!
      create_expression_of_interest if school_partnership.blank?

      create_new_training_period

      true
    end

  private

    def lead_provider_changed?
      old_lead_provider != lead_provider
    end

    def finish_existing_at_school_periods!
      ActiveRecord::Base.transaction do
        teacher.mentor_at_school_periods.ongoing_on(finished_on).each do |period|
          finish_mentorship_periods!(period)
          finish_training_periods!(period)
        end
      end
    end

    def finish_mentorship_periods!(period)
      period.mentorship_periods.ongoing_on(finished_on).each do |mentorship_period|
        MentorshipPeriods::Finish.new(mentorship_period:, finished_on:, author:).finish!
      end
    end

    def finish_training_periods!(period)
      period.training_periods.ongoing_on(finished_on).each do |training_period|
        TrainingPeriods::Finish.mentor_training(training_period:, mentor_at_school_period: period, finished_on:, author:).finish!
      end
    end

    def training_periods
      mentor_at_school_period.training_periods.ongoing
    end

    def create_new_training_period
      ActiveRecord::Base.transaction do
        TrainingPeriods::Create.new(
          period: mentor_at_school_period,
          started_on:,
          school_partnership:,
          expression_of_interest:,
          training_programme: 'provider_led'
        ).call
      end
    end

    def expression_of_interest
      @expression_of_interest ||= create_expression_of_interest
    end

    def create_expression_of_interest
      ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period_year: current_year)
    end

    def school_partnership
      SchoolPartnership
      .joins(:lead_provider_delivery_partnership)
      .joins(:active_lead_provider)
      .where(school:, active_lead_provider: { lead_provider: })
      .for_contract_period(current_year)
      .first
    end

    def school
      mentor_at_school_period.school
    end

    def current_year
      ContractPeriod.containing_date(Time.zone.today).year
    end

    # TODO: dates
    def finished_on
      Time.zone.today
    end

    def started_on
      finished_on + 1
    end

    def teacher
      mentor_at_school_period.teacher
    end

    def mentor_trn
      mentor_at_school_period.teacher.trn
    end

    # def ect_at_school_period
    #   ect_at_school_period
    # end

    def latest_registration_choice
      MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: mentor_trn)
    end

    def old_lead_provider
      latest_registration_choice.lead_provider
    end
  end
end
