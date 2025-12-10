RSpec.shared_examples "an induction redirectable route" do
  context "induction redirection" do
    let!(:induction_tutor_last_nominated_in) { FactoryBot.create(:contract_period, year:) }
    let(:year) { Time.zone.now.year }
    let!(:school) { FactoryBot.create(:school, induction_tutor_last_nominated_in:, induction_tutor_name:, induction_tutor_email:) }
    let(:induction_tutor_name) { Faker::Name.name }
    let(:induction_tutor_email) { Faker::Internet.email }

    context "when signed in as a school user" do
      before { sign_in_as(:school_user, school:) }

      context "when the feature is disabled" do
        it "does not redirect" do
          subject

          expect(response).not_to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
        end
      end

      context "when the feature is enabled", :enable_prompt_for_school_induction_tutor_details do
        context "when the school's induction tutor has never been confirmed" do
          let(:induction_tutor_last_nominated_in) { nil }

          it "redirects to the wizard" do
            subject

            expect(response).to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end

        context "when the school's induction tutor needs to update information" do
          let(:year) { 2024 }

          it "redirects to the wizard" do
            FactoryBot.create(:contract_period, year: Time.zone.now.year)

            subject
            expect(response).to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end

        context "when the school's induction tutor does not need to update information" do
          it "does not redirect" do
            subject

            expect(response).not_to redirect_to(schools_confirm_existing_induction_tutor_wizard_edit_path)
          end
        end
      end
    end

    context "when signed in as a dfe user" do
    end
  end
end
