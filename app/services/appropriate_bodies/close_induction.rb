module AppropriateBodies
  # Closing an ongoing induction period comes in three flavours:
  #
  # 1. RecordPass#pass!
  # 2. RecordFail#fail!
  # 3. RecordRelease#release!
  class CloseInduction
    class TeacherHasNoOngoingInductionPeriod < StandardError; end

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :appropriate_body
    attribute :pending_induction_submission
    attribute :author

    def call
      raise TeacherHasNoOngoingInductionPeriod if ongoing_induction_period.blank?
    end

  private

    delegate :ongoing_induction_period,
             :first_induction_period,
             :last_induction_period,
             to: :teacher

    delegate :trn,
             :number_of_terms,
             :finished_on,
             to: :pending_induction_submission

    def teacher
      @teacher ||= Teacher.find_by!(trn:)
    end

    def close_induction_period(outcome: nil)
      ongoing_induction_period.update!(number_of_terms:, finished_on:, outcome:)
    end

    def delete_submission
      pending_induction_submission.update!(delete_at: 24.hours.from_now)
    end
  end
end
