module Teachers
  # Renders the form fields for recording an induction outcome
  # and shared between admin console and appropriate bodies
  class OutcomeFormFieldsComponent < ApplicationComponent
    attr_reader :form, :appropriate_body_period

    include UserModes

    # @param mode [Symbol] either :admin or :appropriate_body
    # @param form [GOVUKDesignSystemFormBuilder::FormBuilder]
    # @param appropriate_body [AppropriateBodyPeriod]
    def initialize(mode:, form:, appropriate_body_period:)
      super

      @form = form
      @appropriate_body_period = appropriate_body_period
    end

  private

    def finished_on_legend
      return "When did their induction end with #{appropriate_body_period.name}?" if appropriate_body_mode?

      "When did they complete their induction?"
    end

    def number_of_terms_label
      return "How many terms of induction did they spend with you?" if appropriate_body_mode?

      "How many terms of induction did they complete?"
    end
  end
end
