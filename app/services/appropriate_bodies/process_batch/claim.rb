module AppropriateBodies
  module ProcessBatch
    # Management of registration and new induction periods in bulk via CSV upload
    class Claim < Base
      # @return [Array<Boolean>] convert the valid submissions into permanent records
      def complete!
        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

          register!
        rescue StandardError => e
          capture_error(e.message)
          next
        end

        # Batch error reporting
      rescue StandardError => e
        pending_induction_submission_batch.update(error_message: e.message)
      end

      # @return [nil] validate each row and create a submission capturing the errors
      def process!
        pending_induction_submission_batch.rows.each do |row|
          @row = row
          @pending_induction_submission = sparse_pending_induction_submission

          # next if fails_pre_checks?
          next if incorrectly_formatted?

          if teacher
            teacher_name = ::Teachers::Name.new(teacher).full_name

            if induction_periods.last_induction_period.outcome.eql?('pass')
              capture_error("#{teacher_name} has already passed their induction")
              next
            end

            if induction_periods.last_induction_period.outcome.eql?('fail')
              capture_error("#{teacher_name} has already failed their induction")
              next
            end
          end

          validate_submission!

          # Induction start date must not overlap with any other induction periods
          # Induction start date must not be before QTS date
        rescue ::TRS::Errors::TeacherNotFound
          capture_error('TRN and date of birth do not match')
          next
        rescue Errors::TeacherHasActiveInductionPeriodWithCurrentAB
          capture_error("#{name} is already claimed by your appropriate body")
          next
        rescue Errors::TeacherHasActiveInductionPeriodWithAnotherAB
          capture_error("#{name} is already claimed by another appropriate body")
          next
        rescue ::TRS::Errors::ProhibitedFromTeaching
          capture_error("#{name} is prohibited from teaching")
          next
        rescue ::TRS::Errors::QTSNotAwarded
          capture_error("#{name} does not have their qualified teacher status (QTS)")
          next
        rescue StandardError => e
          # capture_error('Something went wrong. You’ll need to try again later')
          capture_error(e.message)
          next
        end

      # Batch error reporting
      rescue StandardError => e
        pending_induction_submission_batch.update(error_message: e.message)
      end

    private

      # @return [Boolean]
      def register!
        PendingInductionSubmissionBatch.transaction do
          if pending_induction_submission.save(context: :register_ect)
            # OPTIMIZE: params effectively passed in twice
            register_ect.register(
              started_on: pending_induction_submission.started_on,
              induction_programme: pending_induction_submission.induction_programme
            )
          else
            false
          end
        end
      end

      # @return [nil, Boolean]
      def validate_submission!
        pending_induction_submission.assign_attributes(
          started_on: row.started_on,
          induction_programme: row.induction_programme.downcase
        )

        find_ect.import_from_trs!
        check_ect.begin_claim!

        pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :find_ect) && pending_induction_submission.save(context: :check_ect) && pending_induction_submission.save(context: :register_ect)
      end

      # @return [Boolean]
      def incorrectly_formatted?
        pending_induction_submission.errors.add(:base, 'Fill in the blanks on this row') if row.blank_cell?
        pending_induction_submission.errors.add(:base, 'Dates must be in the format YYYY-MM-DD') if row.invalid_date?
        pending_induction_submission.errors.add(:base, 'Date of birth must be a real date and the teacher must be between 18 and 100 years old') if row.invalid_age?
        pending_induction_submission.errors.add(:base, 'Enter a valid TRN using 7 digits') if row.invalid_trn?
        # pending_induction_submission.errors.add(:base, 'Induction programme type must be school-led or provider-led') if row.invalid_training_programme?
        pending_induction_submission.errors.add(:base, 'Induction programme type must be DIY, FIP or CIP') if row.invalid_training_programme?

        pending_induction_submission.errors.any? ? pending_induction_submission.playback_errors : false
      end

      # @return [AppropriateBodies::ClaimAnECT::FindECT]
      def find_ect
        ClaimAnECT::FindECT.new(appropriate_body:, pending_induction_submission:)
      end

      # @return [AppropriateBodies::ClaimAnECT::CheckECT]
      def check_ect
        ClaimAnECT::CheckECT.new(appropriate_body:, pending_induction_submission:)
      end

      # @return [AppropriateBodies::ClaimAnECT::RegisterECT]
      def register_ect
        ClaimAnECT::RegisterECT.new(appropriate_body:, pending_induction_submission:, author:)
      end
    end
  end
end
