RSpec.describe Admin::DataFixesWizard::VerifyStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :verify,
      step_params: ActionController::Parameters.new(verify: params),
      author:,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { {} }

  it { is_expected.to delegate_method(:processed_changes).to(:store) }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to be_empty }
  end

  describe "#previous_step" do
    subject(:previous_step) { current_step.previous_step }

    it { is_expected.to eq(:preview) }
  end

  describe "#next_step" do
    subject(:next_step) { current_step.next_step }

    it { is_expected.to eq(:confirmation) }
  end

  describe "#save!" do
    subject(:save!) { current_step.save! }

    before do
      allow(Admin::DataFixes::Changes).to receive(:new).and_return(fake_changes)
    end

    context "when changes are processed successfully" do
      let(:fake_changes) do
        instance_double(
          Admin::DataFixes::Changes,
          process: [{ record_identifier: "Teacher(#1)", action: "destroy" }]
        )
      end

      it { is_expected.to be_truthy }

      it "persists confirmed changes in the store" do
        expect { save! }
          .to change { current_step.store.confirmed_changes }
          .from(nil)
          .to([{ record_identifier: "Teacher(#1)", action: "destroy" }])
      end
    end

    context "when changes are not processed successfully" do
      let(:fake_changes) do
        instance_double(Admin::DataFixes::Changes, process: false)
      end

      it { is_expected.to be_falsey }

      it "does not persist confirmed changes in the store" do
        expect { save! }.not_to(change { current_step.store.confirmed_changes })
      end

      context "but there were confirmed changes already in the store" do
        let(:store) { FactoryBot.build(:session_repository, confirmed_changes:) }
        let(:confirmed_changes) do
          [{ record_identifier: "Teacher(#1)", action: "destroy" }]
        end

        it { is_expected.to be_falsey }

        it "clears the existing processed changes from the store" do
          expect { save! }
            .to change { current_step.store.confirmed_changes }
            .from([{ record_identifier: "Teacher(#1)", action: "destroy" }])
            .to(nil)
        end
      end
    end
  end
end
