module Teachers
  class MergeTRN
    class Eligibility
      def initialize(teacher:)
        @teacher = teacher
      end

      def can_be_merged?
        merge_required? &&
          destination.present? &&
          at_most_one_teacher_has_induction_periods? &&
          ect_periods_at_different_schools_do_not_overlap? &&
          provider_led_training_periods_have_same_contract_period?(:mentor_training_periods) &&
          provider_led_training_periods_have_same_contract_period?(:ect_training_periods)
      end

    private

      attr_reader :teacher

      def destination
        @destination ||= Teacher.find_by_trn(teacher.trs_redirected_to)
      end

      def merge_required?
        teacher.trs_response == "permanent_redirect" && teacher.trs_redirected_to.present?
      end

      def at_most_one_teacher_has_induction_periods?
        !(teacher.induction_periods.any? && destination.induction_periods.any?)
      end

      def ect_periods_at_different_schools_do_not_overlap?
        teacher.ect_at_school_periods.none? do |period|
          destination.ect_at_school_periods
            .where.not(school_id: period.school_id)
            .overlapping_with(period)
            .exists?
        end
      end

      def provider_led_training_periods_have_same_contract_period?(association)
        contract_period_years(association).uniq.size <= 1
      end

      def contract_period_years(association)
        [teacher, destination].flat_map do |record|
          training_period_contract_period_years(record, association)
        end
      end

      def training_period_contract_period_years(record, association)
        periods = record.public_send(association)&.provider_led_training_programme

        [
          *pluck_contract_period_years(periods, :contract_period),
          *pluck_contract_period_years(periods, :expression_of_interest_contract_period)
        ]
      end

      def pluck_contract_period_years(periods, relationship)
        return [] if periods.blank?

        periods.joins(relationship).distinct.pluck(:year)
      end
    end
  end
end
