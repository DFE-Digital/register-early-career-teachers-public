RSpec.shared_examples "an induction redirectable route" do
  context "induction redirection" do
    let(:school) { FactoryBot.create(:school) }
    let(:wizard_path) { "/some-path" }

    before do
      induction_tutor_details = instance_double(
        Schools::InductionTutorDetails,
        update_required?: induction_tutor_details_need_updating,
        wizard_path:
      )
      allow(Schools::InductionTutorDetails)
        .to receive(:new)
        .and_return(induction_tutor_details)
      sign_in_as(:school_user, school:)
    end

    context "when the induction tutor details need updating" do
      let(:induction_tutor_details_need_updating) { true }

      it_behaves_like "redirects to the wizard path"
    end

    context "when the induction tutor details are up to date" do
      let(:induction_tutor_details_need_updating) { false }

      it_behaves_like "does not redirect to the wizard path"
    end
  end
end

RSpec.shared_examples "redirects to the wizard path" do
  it "redirects to the wizard path" do
    subject
    expect(response).to redirect_to(wizard_path)
  end
end

RSpec.shared_examples "does not redirect to the wizard path" do
  it "does not redirect to the wizard path" do
    subject
    expect(response).not_to redirect_to(wizard_path)
  end
end
