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
          training_periods_have_same_contract_period?(:mentor_training_periods) &&
          training_periods_have_same_contract_period?(:ect_training_periods)
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

      def training_periods_have_same_contract_period?(association)
        periods = teacher.public_send(association) + destination.public_send(association)

        periods.map(&:contract_period).uniq.size <= 1
      end
    end
  end
end
