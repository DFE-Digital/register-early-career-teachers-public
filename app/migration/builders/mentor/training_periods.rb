module Builders
  module Mentor
    class TrainingPeriods
      attr_reader :teacher, :training_period_data

      def initialize(teacher:, training_period_data:)
        @teacher = teacher
        @training_period_data = training_period_data
      end

      def build
        success = true
        period_date = Data.define(:started_on, :finished_on)

        training_period_data.each do |period|
          next unless period.training_programme == "full_induction_programme"

          lead_provider = ::LeadProvider.find_by!(name: period.lead_provider)
          delivery_partner = ::DeliveryPartner.find_by!(name: period.delivery_partner)
          lead_provider_active_period = ::LeadProviderActivePeriod.where(lead_provider:, registration_period_id: period.cohort_year)
          lead_provider_delivery_partnership = ::LeadProviderDeliveryPartnership.where(lead_provider_active_period:, delivery_partner:)
          school_partnership = ::SchoolPartnership.find_by(lead_provider_delivery_partnership:)

          period_dates = period_date.new(started_on: period.start_date, finished_on: period.end_date)
          mentor_at_school_period = teacher.mentor_at_school_periods.containing_period(period_dates).first

          ::TrainingPeriod.create!(school_partnership:,
                                   mentor_at_school_period:,
                                   started_on: period.start_date,
                                   finished_on: period.end_date,
                                   ecf_start_induction_record_id: period.start_source_id,
                                   ecf_end_induction_record_id: period.end_source_id)
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
          success = false
        end

        success
      end
    end
  end
end
