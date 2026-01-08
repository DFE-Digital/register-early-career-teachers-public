module Teachers
  module LeadProviderChanger
    class LeadProviderNotChangedError < StandardError; end

    extend ActiveSupport::Concern

    include TrainingPeriodSources

    class_methods do
      def call(*args, **kwargs)
        new(*args, **kwargs).call
      end
    end

    included do
      attr_reader :period,
                  :mentor_at_school_period,
                  :ect_at_school_period,
                  :new_lead_provider,
                  :old_lead_provider,
                  :author

      private :period,
              :old_lead_provider,
              :new_lead_provider,
              :author
    end

    def initialize(period, new_lead_provider:, old_lead_provider:, author:)
      @period = period
      @new_lead_provider = new_lead_provider
      @old_lead_provider = old_lead_provider
      @author = author
    end

    def call
      raise LeadProviderNotChangedError unless lead_provider_changed?

      ActiveRecord::Base.transaction do
        if update_training_period_in_place?
          update_training_period_in_place!
        else
          finish_or_destroy_training_period!
          create_training_period!
        end

        record_lead_provider_updated_event!
      end
    end

  private

    def create_training_period!
      TrainingPeriods::Create.provider_led(
        period:,
        started_on: date_of_transition,
        school_partnership:,
        expression_of_interest:,
        author:
      ).call
    end

    def record_lead_provider_updated_event!
      Events::Record.record_teacher_training_lead_provider_updated_event!(
        old_lead_provider_name: old_lead_provider.name,
        new_lead_provider_name: new_lead_provider.name,
        author:,
        ect_at_school_period:,
        mentor_at_school_period:,
        school:,
        teacher:,
        happened_at: Time.current
      )
    end

    def active_lead_provider
      ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period:)
    end

    def school_partnership
      earliest_matching_school_partnership
    end

    def finish_or_destroy_training_period!
      return unless training_period

      if training_period_confirmed?
        finish_training_period!
      else
        training_period.destroy!
      end
    end

    def training_period_confirmed?
      training_period.school_partnership.present?
    end

    def date_of_transition
      return training_period.started_on if update_training_period_in_place?

      [period.started_on, Date.current].max
    end

    def training_period
      period.current_or_next_training_period
    end

    def update_training_period_in_place?
      training_period.present? && training_period.started_on >= Date.current
    end

    def update_training_period_in_place!
      training_period.update!(
        school_partnership:,
        expression_of_interest:
      )
    end
    delegate :school, to: :period
    delegate :teacher, to: :period

    def lead_provider_changed?
      old_lead_provider != new_lead_provider
    end

    def lead_provider
      new_lead_provider
    end

    alias_method :started_on, :date_of_transition
  end
end
