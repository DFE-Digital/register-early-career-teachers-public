# Steps in Schools::RegisterMentorWizard will have a Schools::RegisterMentor::Mentor instance
# available rather than the wizard store directly.
# The aim of this class is to encapsulate and provide Mentor logic instead of spreading it across the various steps.
#
# This class will depend so much on the multiple data saved in the wizard.store by the steps during the journey
# that has been built on top of it by inheriting from Ruby SimpleDelegator class.
module Schools
  module RegisterMentorWizard
    class Mentor < SimpleDelegator
      def active_at_school?
        active_record_at_school.present?
      end

      def active_record_at_school
        @active_record_at_school ||= MentorAtSchoolPeriods::Search.new.mentor_periods(trn:, urn: school_urn).ongoing.last
      end

      def cant_use_email?
        Schools::TeacherEmail.new(email:, trn:).is_currently_used?
      end

      def corrected_name?
        corrected_name.present?
      end

      def full_name
        @full_name ||= (corrected_name || trs_full_name).strip
      end

      def govuk_date_of_birth
        trs_date_of_birth.to_date&.to_formatted_s(:govuk)
      end

      def in_trs?
        trs_first_name.present?
      end

      def matches_trs_dob?
        return false if [date_of_birth, trs_date_of_birth].any?(&:blank?)

        trs_date_of_birth.to_date == date_of_birth.to_date
      end

      def funding_available?
        if (record = Teacher.find_by(trn:))
          record.eligible_for_mentor_funding?
        else
          !check_ero_mentor.early_roll_out_mentor?
        end
      end

      def check_ero_mentor
        @check_ero_mentor ||= CheckEarlyRollOutMentor.new(trn)
      end

      def register!
        Schools::RegisterMentor.new(trs_first_name:,
                                    trs_last_name:,
                                    corrected_name:,
                                    trn:,
                                    school_urn:,
                                    email:,
                                    **check_ero_mentor.to_h)
                               .register!.tap do
          self.registered = true
        end
      end

      def school
        @school ||= School.find_by_urn(school_urn)
      end

      def trs_full_name
        @trs_full_name ||= [trs_first_name, trs_last_name].join(" ")
      end

    private

      # The wizard store object where we delegate the rest of methods
      def wizard_store
        __getobj__
      end
    end
  end
end
