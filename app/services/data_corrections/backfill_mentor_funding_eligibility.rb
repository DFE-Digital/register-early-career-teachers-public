module DataCorrections
  class BackfillMentorFundingEligibility
    class UnexpectedCandidateCount < StandardError; end

    def initialize(expected_count:, author: Events::SystemAuthor.new)
      @expected_count = Integer(expected_count)
      @author = author
    end

    def preview
      teachers_to_correct.order(:id).ids
    end

    def call
      candidate_ids = preview
      validate_candidate_count!(candidate_ids)

      ApplicationRecord.transaction do
        Teacher.where(id: candidate_ids).find_each do |teacher|
          Teachers::SetMentorFundingEligibility.new(
            teacher:,
            author:
          ).set!
        end
      end

      candidate_ids
    end

  private

    attr_reader :expected_count, :author

    def teachers_to_correct
      Teacher
        .joins(
          mentor_at_school_periods: %i[
            mentorship_periods
            training_periods
          ]
        )
        .where(
          mentor_first_became_eligible_for_training_at: nil,
          mentor_became_ineligible_for_funding_on: nil,
          mentor_became_ineligible_for_funding_reason: nil,
          anonymised_at: nil
        )
        .where(
          training_periods: {
            training_programme: "provider_led"
          }
        )
        .distinct
    end

    def validate_candidate_count!(candidate_ids)
      return if candidate_ids.count == expected_count

      raise UnexpectedCandidateCount,
            "Expected #{expected_count} candidates, found #{candidate_ids.count}"
    end
  end
end
