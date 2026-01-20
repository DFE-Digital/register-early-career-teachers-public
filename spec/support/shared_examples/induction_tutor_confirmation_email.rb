RSpec.shared_examples "induction tutor confirmation email" do
  it "sends a confirmation email" do
    expect { current_step.save! }
      .to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
  end

  context "when induction tutor details are unchanged" do
    let(:school) { FactoryBot.create(:school, induction_tutor_name:, induction_tutor_email:) }

    it "does not send a confirmation email" do
      expect { current_step.save! }
        .not_to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
    end
  end
end
