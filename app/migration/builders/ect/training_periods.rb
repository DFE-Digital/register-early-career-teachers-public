module Builders
  module ECT
    class TrainingPeriods
      attr_reader :teacher, :training_period_data

      def initialize(teacher:, training_period_data:)
        @teacher = teacher
        @training_period_data = training_period_data
      end

      def process!
        training_period_data.each do |period|
          next unless period.training_programme == "full_induction_programme"

          provider_partnership = ::ProviderPartnership.where(lead_provider: ::LeadProvider.find_by!(name: period.lead_provider),
                                                             delivery_partner: ::DeliveryPartner.find_by!(name: period.delivery_partner),
                                                             academic_year_id: period.cohort_year).first

          period_dates = OpenStruct.new(started_on: period.start_date, finished_on: period.end_date)
          ect_at_school_period = teacher.ect_at_school_periods.containing_period(period_dates).first

          ::TrainingPeriod.create!(provider_partnership:,
                                   ect_at_school_period:,
                                   started_on: period.start_date,
                                   finished_on: period.end_date,
                                   legacy_start_id: period.start_source_id,
                                   legacy_end_id: period.end_source_id)
        end
      end
    end
  end
end
