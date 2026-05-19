RSpec.shared_examples "an induction redirectable route" do
  context "induction redirection" do
    let!(:current_contract_period) do
      FactoryBot.create(:contract_period, :current)
    end
    let(:year_induction_tutor_nominated_in) { current_contract_period.year }

    let!(:school) do
      FactoryBot.create(:school, :without_induction_tutor,
                        induction_tutor_last_nominated_in:,
                        induction_tutor_name:,
                        induction_tutor_email:)
    end
    let!(:induction_tutor_last_nominated_in) do
      FactoryBot.create(:contract_period, year: year_induction_tutor_nominated_in)
    end
    let(:induction_tutor_name) { Faker::Name.name }
    let(:induction_tutor_email) { Faker::Internet.email }

    context "when signed in as a school user" do
      before { sign_in_as(:school_user, school:) }

      context "when the school's induction tutor has never been confirmed" do
        let(:induction_tutor_last_nominated_in) { nil }

        it_behaves_like "redirects to confirmation wizard"
      end

      context "when the school's induction tutor is not set" do
        let(:induction_tutor_last_nominated_in) { nil }
        let(:induction_tutor_name) { nil }
        let(:induction_tutor_email) { nil }

        it_behaves_like "redirects to new wizard"
      end

      context "when the school's induction tutor needs to update information" do
        let(:year_induction_tutor_nominated_in) do
          current_contract_period.year - 1
        end

        context "when we are in the current contract period" do
          it_behaves_like "redirects to confirmation wizard"
        end

        context "when we are between contract periods" do
          let!(:current_contract_period) do
            FactoryBot.create(:contract_period, :current)
          end
          let!(:upcoming_contract_period) do
            FactoryBot.create(
              :contract_period,
              :next,
              started_on: current_contract_period.finished_on + 1.week,
              finished_on: current_contract_period.finished_on + 1.year
            )
          end

          before do
            travel_to current_contract_period.finished_on + 1.day
            # We need to sign in again after time travel
            sign_in_as(:school_user, school:)
          end

          it_behaves_like "redirects to confirmation wizard"
        end
      end

      context "when the school's induction tutor does not need to update information" do
        it_behaves_like "does not redirect to wizard"
      end
    end

    context "when signed in as a dfe user" do
      let(:user) { FactoryBot.create(:user, :admin) }

      before { sign_in_as(:dfe_user, user:) }

      context "when the school's induction tutor has never been confirmed" do
        let(:induction_tutor_last_nominated_in) { nil }

        it_behaves_like "does not redirect to wizard"
      end

      context "when the school's induction tutor is not set" do
        let(:induction_tutor_last_nominated_in) { nil }
        let(:induction_tutor_name) { nil }
        let(:induction_tutor_email) { nil }

        it_behaves_like "does not redirect to wizard"
      end

      context "when the school's induction tutor needs to update information" do
        let(:year_induction_tutor_nominated_in) do
          current_contract_period.year - 1
        end

        context "when we are in the current contract period" do
          it_behaves_like "does not redirect to wizard"
        end

        context "when we are between contract periods" do
          let!(:current_contract_period) do
            FactoryBot.create(:contract_period, :current)
          end
          let!(:upcoming_contract_period) do
            FactoryBot.create(
              :contract_period,
              :next,
              started_on: current_contract_period.finished_on + 1.week,
              finished_on: current_contract_period.finished_on + 1.year
            )
          end

          before do
            travel_to current_contract_period.finished_on + 1.day
            # We need to sign in again after time travel
            sign_in_as(:dfe_user, user:)
          end

          it_behaves_like "does not redirect to wizard"
        end
      end
    end

    context "when signed in as an appropriate body" do
      let(:appropriate_body) { FactoryBot.create(:appropriate_body_period) }

      before { sign_in_as(:appropriate_body_user, appropriate_body:) }

      context "when the school's induction tutor has never been confirmed" do
        let(:induction_tutor_last_nominated_in) { nil }

        it_behaves_like "does not redirect to wizard"
      end

      context "when the school's induction tutor is not set" do
        let(:induction_tutor_last_nominated_in) { nil }
        let(:induction_tutor_name) { nil }
        let(:induction_tutor_email) { nil }

        it_behaves_like "does not redirect to wizard"
      end

      context "when the school's induction tutor needs to update information" do
        let(:year_induction_tutor_nominated_in) do
          current_contract_period.year - 1
        end

        context "when we are in the current contract period" do
          it_behaves_like "does not redirect to wizard"
        end

        context "when we are between contract periods" do
          let!(:current_contract_period) do
            FactoryBot.create(:contract_period, :current)
          end
          let!(:upcoming_contract_period) do
            FactoryBot.create(
              :contract_period,
              :next,
              started_on: current_contract_period.finished_on + 1.week,
              finished_on: current_contract_period.finished_on + 1.year
            )
          end

          before do
            travel_to current_contract_period.finished_on + 1.day
            # We need to sign in again after time travel
            sign_in_as(:appropriate_body_user, appropriate_body:)
          end

          it_behaves_like "does not redirect to wizard"
        end
      end
    end
  end
end

RSpec.shared_examples "redirects to confirmation wizard" do
  it "redirects to the wizard" do
    subject
    expect(response).to redirect_to(schools_induction_tutor_confirm_existing_induction_tutor_wizard_edit_path)
  end
end

RSpec.shared_examples "redirects to new wizard" do
  it "redirects to the wizard" do
    subject
    expect(response).to redirect_to(schools_induction_tutor_new_induction_tutor_wizard_edit_path)
  end
end

RSpec.shared_examples "does not redirect to wizard" do
  it "does not redirect to either wizard" do
    subject
    expect(response).not_to redirect_to(schools_induction_tutor_confirm_existing_induction_tutor_wizard_edit_path)
    expect(response).not_to redirect_to(schools_induction_tutor_new_induction_tutor_wizard_edit_path)
  end
end
