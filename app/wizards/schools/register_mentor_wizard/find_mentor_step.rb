module Schools
  module RegisterMentorWizard
    class FindMentorStep < Step
      attr_accessor :trn, :date_of_birth

      validates :trn, teacher_reference_number: true
      validates :date_of_birth, date_of_birth: true

      def self.permitted_params
        %i[trn date_of_birth]
      end

      def next_step
        return :trn_not_found unless mentor.in_trs?
        return :national_insurance_number unless mentor.matches_trs_dob?
        return :already_active_at_school if mentor.active_at_school?
        return :cannot_register_mentor if trs_teacher.prohibited_from_teaching?

        :review_mentor_details
      end

    private

      def persist
        mentor.update(trn:,
                      date_of_birth: date_of_birth.values.join("-"),
                      trs_date_of_birth: trs_teacher.date_of_birth,
                      trs_first_name: trs_teacher.first_name,
                      trs_last_name: trs_teacher.last_name)
      end

      def trs_teacher
        @trs_teacher ||= fetch_trs_teacher(trn:)
      end
    end
  end
end
