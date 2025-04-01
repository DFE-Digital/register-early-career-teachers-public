# frozen_string_literal: true

module Schools
  module RegisterMentorWizard
    class NationalInsuranceNumberStep < Step
      attr_accessor :national_insurance_number

      validates :national_insurance_number, national_insurance_number: true

      def self.permitted_params
        %i[national_insurance_number]
      end

      def next_step
        return :not_found unless mentor.in_trs?
        return :already_active_at_school if mentor.active_at_school?
        return :cannot_register_mentor if trs_teacher.prohibited_from_teaching?

        :review_mentor_details
      end

      def previous_step
        :find_mentor
      end

    private

      def persist
        mentor.update(national_insurance_number:,
                      prohibited_from_teaching: trs_teacher.prohibited_from_teaching?,
                      trs_date_of_birth: trs_teacher.date_of_birth,
                      trs_first_name: trs_teacher.first_name,
                      trs_last_name: trs_teacher.last_name)
      end

      def trs_teacher
        @trs_teacher ||= fetch_trs_teacher(trn: mentor.trn, national_insurance_number:)
      end
    end
  end
end
