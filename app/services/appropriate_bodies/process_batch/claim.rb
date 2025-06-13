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

          next if fails_pre_checks?

          validate_submission!
        rescue StandardError => e
          # replace after bug party
          capture_error(e.message) # capture_error("Something went wrong. You’ll need to try again later")
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
      def fails_pre_checks?
        if incorrectly_formatted?
          true
        elsif (trs_error = fetch_trs_details!)
          capture_error(trs_error)
          true
        elsif teacher
          if induction_periods.last_induction_period.outcome.eql?('pass')
            capture_error("#{name} has already passed their induction")
            true
          elsif induction_periods.last_induction_period.outcome.eql?('fail')
            capture_error("#{name} has already failed their induction")
            true
          elsif claimed_by_another_ab?
            capture_error("#{name} is already claimed by another appropriate body")
            true
          elsif !claimed_by_another_ab?
            capture_error("#{name} is already claimed by your appropriate body")
            true
          elsif induction_periods.overlapping_with?(pending_induction_submission)
            capture_error('Induction start date must not overlap with any other induction periods')
            true
          end
        elsif prohibited_from_teaching?
          capture_error("#{name} is prohibited from teaching")
          true
        elsif pending_induction_submission.trs_qts_awarded_on.blank?
          capture_error("#{name} does not have their qualified teacher status (QTS)")
          true
        # elsif pending_induction_submission&.started_on < pending_induction_submission.trs_qts_awarded_on
        #   capture_error("Induction start date must not be before QTS date (#{pending_induction_submission.trs_qts_awarded_on.to_fs(:govuk)})")
        #   true
        else
          false
        end
      end

      # @see TRS::Teacher#prohibited_from_teaching?
      # @return [Boolean]
      def prohibited_from_teaching?
        pending_induction_submission.trs_alerts&.any? { |alert| alert.dig('alertType', 'alertCategory', 'alertCategoryId') == ::TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID }
      end

      # @return [Boolean]
      def incorrectly_formatted?
        super

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
