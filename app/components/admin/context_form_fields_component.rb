module Admin
  class ContextFormFieldsComponent < ApplicationComponent
    attr_reader :form

    # @param form [GOVUKDesignSystemFormBuilder::FormBuilder]
    def initialize(form:)
      @form = form
    end
  end
end
