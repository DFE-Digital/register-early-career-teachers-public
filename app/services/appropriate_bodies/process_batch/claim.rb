module AppropriateBodies
  module ProcessBatch
    # Management of registration and new induction periods in bulk via CSV upload
    class Claim < Base
      # @return [nil, true] convert the valid submissions into permanent records
      def complete!
        pending_induction_submission_batch.completing!

        pending_induction_submission_batch.pending_induction_submissions.without_errors.map do |pending_induction_submission|
          @pending_induction_submission = pending_induction_submission

          # OPTIMIZE: params effectively passed in twice
          register_ect.register(
            started_on: pending_induction_submission.started_on,
            induction_programme: pending_induction_submission.induction_programme
          )
          true
        rescue StandardError => e
          capture_error(e.message)
          next(false)
        end

        pending_induction_submission_batch.tally!
        pending_induction_submission_batch.completed!
        pending_induction_submission_batch.redact!
      end

    private

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
          if induction_periods.last_induction_period&.outcome.eql?('pass')
            capture_error("#{name} has already passed their induction")
            true
          elsif induction_periods.last_induction_period&.outcome.eql?('fail')
            capture_error("#{name} has already failed their induction")
            true
          elsif claimed_by_another_ab?
            capture_error("#{name} is already claimed by another appropriate body")
            true
          elsif overlapping_with_induction_period?
            capture_error('Induction start date must not overlap with any other induction periods')
            true
          elsif !claimed_by_another_ab?
            capture_error("#{name} is already claimed by your appropriate body")
            true
          end
        elsif prohibited_from_teaching?
          capture_error("#{name} is prohibited from teaching")
          true
        elsif pending_induction_submission.trs_qts_awarded_on.blank?
          capture_error("#{name} does not have their qualified teacher status (QTS)")
          true
        elsif predates_qts_award?
          capture_error("Induction start date must not be before QTS date (#{pending_induction_submission.trs_qts_awarded_on.to_fs(:govuk)})")
          true
        else
          false
        end
      end

      # @return [Boolean]
      def overlapping_with_induction_period?
        induction_periods.overlapping_with?(row.started_on)
      end

      # @return [Boolean]
      def predates_qts_award?
        Date.parse(row.started_on.to_s) < pending_induction_submission.trs_qts_awarded_on
      rescue Date::Error
        true
      end

      # @return [Boolean] started_on before 1 September 2021
      def predates_ecf_rollout?
        Date.parse(row.started_on.to_s) <= ::ECF_ROLLOUT_DATE
      rescue Date::Error
        true
      end

      # @see TRS::Teacher#prohibited_from_teaching?
      # @return [Boolean]
      def prohibited_from_teaching?
        pending_induction_submission.trs_alerts&.any? { |alert| alert.dig('alertType', 'alertCategory', 'alertCategoryId') == ::TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID }
      end

      # @return [Boolean]
      def incorrectly_formatted?
        super

        pending_induction_submission.errors.add(:base, 'Induction start date must be after 1 September 2021') if predates_ecf_rollout?
        # TODO: ready for training programme types update
        # pending_induction_submission.errors.add(:base, 'Induction programme type must be school-led or provider-led') if invalid_training_programme?
        pending_induction_submission.errors.add(:base, 'Induction programme type must be DIY, FIP or CIP') if invalid_training_programme?

        pending_induction_submission.errors.any? ? pending_induction_submission.playback_errors : false
      end

      # @return [Boolean] school-led, provider-led (case-insensitive) new style
      # @return [Boolean] diy, cip, fip (case-insensitive) old style
      def invalid_training_programme?
        row.induction_programme !~ /\A(diy|cip|fip)\z/i
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
