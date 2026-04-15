class ApplicationWizardStep < DfE::Wizard::Step
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  class EmptyStoreError < StandardError; end

  # Subclasses with seeded stores can declare which keys must be present in
  # the store for a CheckAnswers submission to be considered valid. Defaults
  # to nil, which falls back to a `store.empty?` check.
  class_attribute :expected_store_keys, instance_accessor: false

  # Guard against submitting check-answers with an empty session store due to
  # concurrent tabs/windows or back/forward navigation.
  RejectEmptyStoreOnCheckAnswers = Module.new do
    def save!
      raise EmptyStoreError if step_name == "CheckAnswers" && store_missing_data?

      super
    end

  private

    def store_missing_data?
      if self.class.expected_store_keys
        self.class.expected_store_keys.any? { |key| store[key].blank? }
      else
        store.empty?
      end
    end
  end

  # Prepend on every subclass so the guard intercepts subclass-defined save!
  def self.inherited(subclass)
    super
    subclass.prepend(RejectEmptyStoreOnCheckAnswers)
  end

  # Populate a step attributes if no values are provided at initialization time.
  # Usually to be populated from the wizard store.
  def initialize(args = {})
    super
    pre_populate_attributes unless any_permitted_param?(args)
  end

private

  def any_permitted_param?(args)
    args.keys.map(&:to_sym).intersect?(self.class.permitted_params)
  end

  def pre_populate_attributes
    raise NotImplementedError
  end
end
