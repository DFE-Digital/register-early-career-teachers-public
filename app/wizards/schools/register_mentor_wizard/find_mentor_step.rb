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
        return :cannot_mentor_themself if mentor.trn == ect.trn
        return :national_insurance_number unless mentor.matches_trs_dob?
        return :already_active_at_school if mentor.active_at_school?
        return :cannot_register_mentor if trs_teacher.prohibited_from_teaching?

        :review_mentor_details
      end

    private

      def formatted_trn
        @formatted_trn ||= Validation::TeacherReferenceNumber.new(trn).formatted_trn
      end

      def persist
        mentor.update(trn: formatted_trn,
                      date_of_birth: date_of_birth.values.join("-"),
                      trs_date_of_birth: trs_teacher.date_of_birth,
                      trs_first_name: trs_teacher.first_name,
                      trs_last_name: trs_teacher.last_name)
      end

      def pre_populate_attributes
        self.trn = mentor.trn
        self.date_of_birth = Schools::Validation::DateOfBirth.new(mentor.date_of_birth).date_as_hash
      end

      def trs_teacher
        @trs_teacher ||= fetch_trs_teacher(trn: formatted_trn)
      end
    end
  end
end
