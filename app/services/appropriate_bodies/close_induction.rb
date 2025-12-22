module AppropriateBodies
  # Closing an ongoing induction period comes in three flavours:
  #
  # 1. RecordPass
  # 2. RecordFail
  # 3. RecordRelease
  class CloseInduction
    class TeacherHasNoOngoingInductionPeriod < StandardError; end

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :teacher
    attribute :appropriate_body
    attribute :author

    validates :finished_on, presence: { message: "Enter a finish date" }
    validates :fail_confirmation_sent_on, presence: { message: "Enter a date written confirmation of failed Induction" }, if: :failed_outcome?
    validates :number_of_terms, presence: { message: "Enter a number of terms" }

    def self.induction_params
      permitted = %i[finished_on number_of_terms]
      permitted << :fail_confirmation_sent_on if self == AppropriateBodies::RecordFail || self == Admin::RecordFail

      { model_name.param_key => permitted }
    end

    def outcome = nil

    def call(params)
      raise TeacherHasNoOngoingInductionPeriod if ongoing_induction_period.blank?

      pending_induction_submission.assign_attributes(outcome:, **params)

      validate!
    end

  private

    delegate :trn,
             :ongoing_induction_period,
             :first_induction_period,
             :last_induction_period,
             to: :teacher

    delegate :number_of_terms,
             :finished_on,
             :fail_confirmation_sent_on,
             to: :pending_induction_submission

    def close_induction_period
      ongoing_induction_period.update!(number_of_terms:, finished_on:, fail_confirmation_sent_on:, outcome:)
    end

    def pending_induction_submission
      @pending_induction_submission ||= PendingInductionSubmissions::Build.closing_induction_period(
        ongoing_induction_period,
        appropriate_body_id: appropriate_body.id,
        trn:
      ).pending_induction_submission
    end

    def delete_submission
      pending_induction_submission.update!(delete_at: 24.hours.from_now)
    end

    def validate_submission(context:)
      if pending_induction_submission.invalid?(context:)
        pending_induction_submission.errors.each do |error|
          errors.add(error.attribute, error.message)
        end
      end
    end

    def failed_outcome?
      is_a?(AppropriateBodies::RecordFail)
    end
  end
end
