module Teachers
  # Renders the form fields for recording an induction outcome
  # and shared between admin console and appropriate bodies
  class OutcomeFormComponent < ApplicationComponent
    attr_reader :form,
                :appropriate_body

    # @param form [GOVUKDesignSystemFormBuilder::FormBuilder]
    # @param appropriate_body [AppropriateBody, nil]
    def initialize(form:, appropriate_body: nil)
      @form = form
      @appropriate_body = appropriate_body
    end

  private

    def finished_on_legend
      return "When did they move from #{appropriate_body.name}?" if appropriate_body_mode?

      "When did they complete their induction?"
    end

    def number_of_terms_label
      return "How many terms of induction did they spend with you?" if appropriate_body_mode?

      "How many terms of induction did they complete?"
    end

    def appropriate_body_mode?
      appropriate_body.present?
    end
  end
end
