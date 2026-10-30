module Teachers
  module TRN
    class Eligibility
      def initialize(teacher:, new_trn: nil, destination: nil)
        @teacher = teacher
        @new_trn = new_trn
        @destination = destination
      end

      def can_be_merged?
        merge_required? &&
          destination.present? &&
          destination_has_expected_trn? &&
          source_and_destination_are_different? &&
          at_most_one_teacher_has_induction_periods? &&
          ect_periods_at_different_schools_do_not_overlap? &&
          provider_led_training_periods_have_same_contract_period?(:mentor_training_periods) &&
          provider_led_training_periods_have_same_contract_period?(:ect_training_periods)
      end

      def can_be_replaced?
        merge_required? &&
          destination.nil? &&
          source_and_destination_are_different? &&
          !another_teacher_redirected_to_destination?
      end

    private

      attr_reader :teacher

      def new_trn
        @new_trn || teacher.trs_redirected_to
      end

      def destination
        @destination ||= Teacher.find_by_trn(new_trn)
      end

      def merge_required?
        (teacher.trs_response_gone? && @new_trn.present?) ||
          (teacher.trs_response == "permanent_redirect" && teacher.trs_redirected_to.present?)
      end

      def destination_has_expected_trn?
        destination.trn == new_trn
      end

      def source_and_destination_are_different?
        new_trn != teacher.trn
      end

      def another_teacher_redirected_to_destination?
        Teacher.where.not(id: teacher.id).exists?(trs_redirected_to: new_trn)
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
