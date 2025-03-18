module Teachers
  class OutcomeFormComponent < ViewComponent::Base
    attr_reader :form, :teacher, :is_admin, :appropriate_body

    def initialize(form:, teacher:, is_admin:, appropriate_body: nil)
      @form = form
      @teacher = teacher
      @is_admin = is_admin
      @appropriate_body = appropriate_body
    end

    def date_legend_text
      if is_admin
        "When did they complete their induction?"
      else
        "When did they move from #{appropriate_body.name}?"
      end
    end

    def terms_label_text
      if is_admin
        "How many terms of induction did they complete?"
      else
        "How many terms of induction did they spend with you?"
      end
    end

    def teacher_induction_date_hint_text
      "For example, 20 4 #{Date.current.year.pred}"
    end
  end
end
