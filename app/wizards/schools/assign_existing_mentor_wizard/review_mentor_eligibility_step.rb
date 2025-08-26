module Schools
  module AssignExistingMentorWizard
    class ReviewMentorEligibilityStep < Step
      # previous step is outside wizard
      def next_step = :confirmation

    private

      def persist
        AssignMentor.new(
          ect: wizard.context.ect_at_school_period,
          mentor: wizard.context.mentor_at_school_period,
          author: wizard.author
        ).assign!

        # TODO: Update the LP if there is a confirmed partnership, if not add an EOI
      end
    end
  end
end
