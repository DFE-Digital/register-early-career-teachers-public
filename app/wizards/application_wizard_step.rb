class ApplicationWizardStep < DfE::Wizard::Step
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
