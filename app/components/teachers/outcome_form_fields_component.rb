module Teachers
  # Renders the form fields for recording an induction outcome
  # and shared between admin console and appropriate bodies
  class OutcomeFormFieldsComponent < ApplicationComponent
    attr_reader :form, :appropriate_body

    include UserModes

    # @param mode [Symbol] either :admin or :appropriate_body
    # @param form [GOVUKDesignSystemFormBuilder::FormBuilder]
    # @param appropriate_body [AppropriateBody]
    def initialize(mode:, form:, appropriate_body:, failed:)
      super

      @form = form
      @appropriate_body = appropriate_body
      @failed = failed
    end

  private

    def finished_on_legend
      return "When did their induction end with #{appropriate_body.name}?" if appropriate_body_mode?

      "When did they complete their induction?"
    end

    def written_fail_confirm_legend
      return "Enter the date you sent them written confirmation of their failed induction?" if appropriate_body_mode?

      "When did you send written confirmation of their failed induction?"
    end


    def number_of_terms_label
      return "How many terms of induction did they spend with you?" if appropriate_body_mode?

      "How many terms of induction did they complete?"
    end

    def failed?
      @failed
    end
  end
end
