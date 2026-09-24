# Merge induction periods between two TRNs
# Called after a TRN merge in TRS has been detected
module Teachers
  module Merge
    class InductionPeriods
      def initialize(teacher:)
        @teacher = teacher
        @sync_required = false
      end

      def move!
        return unless merge_required?
        return if destination.blank?
        return if any_overlapping_periods?

        @source_earliest_started_on = source_periods.minimum(:started_on)
        return unless @source_earliest_started_on

        @sync_required = earlier_induction_period_on_source?

        ActiveRecord::Base.transaction do
          source.induction_periods.find_each { |period| period.update!(teacher: destination) }
          source.induction_extensions.find_each { |extension| extension.update!(teacher: destination) }
        end
      end

      def sync
        return unless @sync_required

        BeginECTInductionJob.perform_now(trn: destination.trn, start_date: @source_earliest_started_on)
      end

    private

      attr_reader :teacher
      alias_method :source, :teacher

      def destination
        @destination ||= Teacher.find_by_trn(teacher.trs_redirected_to)
      end

      def merge_required?
        teacher.trs_response == "permanent_redirect" && teacher.trs_redirected_to.present?
      end

      def any_overlapping_periods?
        source_periods.any? do
          destination_periods.overlapping_with(it).exists?
        end
      end

      def earlier_induction_period_on_source?
        destination_earliest_started_on = destination_periods.minimum(:started_on)

        destination_earliest_started_on.nil? || @source_earliest_started_on < destination_earliest_started_on
      end

      def source_periods
        @source_periods ||= source.induction_periods
      end

      def destination_periods
        @destination_periods ||= destination.induction_periods
      end
    end
  end
end
