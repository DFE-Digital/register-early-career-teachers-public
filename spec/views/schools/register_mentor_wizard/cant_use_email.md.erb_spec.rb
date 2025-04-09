require_relative './shared_examples/cant_use_email_view'

RSpec.describe "schools/register_mentor_wizard/cant_use_email.md.erb" do
  it_behaves_like "a can't use email step view",
                  current_step: :cant_use_email,
                  back_path: :schools_register_mentor_wizard_email_address_path
end
