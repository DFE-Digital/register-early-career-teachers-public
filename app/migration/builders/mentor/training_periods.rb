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
          active_lead_provider = ::ActiveLeadProvider.find_by!(lead_provider:, contract_period_id: period.cohort_year)
          delivery_partner = ::DeliveryPartner.find_by!(name: period.delivery_partner)
          lead_provider_delivery_partnership = ::LeadProviderDeliveryPartnership.find_by!(active_lead_provider:, delivery_partner:)

          period_dates = period_date.new(started_on: period.start_date, finished_on: period.end_date)
          mentor_at_school_period = teacher.mentor_at_school_periods.containing_period(period_dates).first

          school_partnership = ::SchoolPartnership.find_by!(lead_provider_delivery_partnership:, school: mentor_at_school_period.school)

          training_period = ::TrainingPeriod.find_or_initialize_by(ecf_start_induction_record_id: period.start_source_id)
          training_period.mentor_at_school_period = mentor_at_school_period
          training_period.school_partnership = school_partnership
          training_period.started_on = period.start_date
          training_period.finished_on = period.end_date
          training_period.ecf_end_induction_record_id = period.end_source_id
          training_period.save!
        rescue ActiveRecord::ActiveRecordError => e
          ::TeacherMigrationFailure.create!(teacher:, model: :training_period, message: e.message, migration_item_id: period.start_source_id, migration_item_type: "Migration::InductionRecord")
          success = false
        end

        success
      end
    end
  end
end
