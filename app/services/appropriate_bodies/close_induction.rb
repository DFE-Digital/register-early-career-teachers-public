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
    validates :number_of_terms, presence: { message: "Enter a number of terms" }

    def self.induction_params
      { model_name.param_key => %i[finished_on number_of_terms] }
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
      ongoing_induction_period.update!(number_of_terms:, finished_on:, outcome:)
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

    # We may allow inductions to be closed with a future date,
    # but for MVP inductions can only be closed with today's date or earlier.
    # To keep it simple therefore we close ECT, training and mentorship periods
    # on today's date unless it is already closed.
    # Anything that starts today or in the future is destroyed first.
    def finish_ect_period_today
      return unless ect_at_school_period
      return if ect_at_school_period.finished_on.present?

      ECTAtSchoolPeriods::Finish.new(ect_at_school_period:, finished_on: Time.zone.today, author:, record_event: false).finish!
    end

    def ect_at_school_period
      ongoing_induction_period.teacher.ect_at_school_periods.latest_first.first
    end

    def destroy_unstarted_ect_period!
      ECTAtSchoolPeriods::Destroy.call(ect_at_school_period:, author:)
    end

    def mentorship_period
      ect_at_school_period&.latest_mentorship_period
    end

    def training_period
      ect_at_school_period&.latest_training_period
    end
  end
end
