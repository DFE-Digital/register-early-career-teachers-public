class ApplicationWizard < DfE::Wizard::Base
  def allowed_steps = raise NotImplementedError

  def allowed_step? = allowed_steps.include?(current_step_name)

  def allowed_step_path = current_step.next_step_path(allowed_step_klass)

private

  def allowed_step_klass = find_step(allowed_steps.last)
end
