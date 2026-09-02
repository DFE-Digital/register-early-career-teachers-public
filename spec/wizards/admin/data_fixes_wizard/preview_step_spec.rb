RSpec.describe Admin::DataFixesWizard::PreviewStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :preview,
      step_params: ActionController::Parameters.new(preview: params),
      author:,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository, parsed_rows:) }
  let(:author) { FactoryBot.build(:dfe_user, role: :product_team) }
  let(:params) { {} }
  let(:parsed_rows) { [{ test: "something" }, { test: "another_thing" }] }

  it { is_expected.to delegate_method(:errors).to(:changes) }
  it { is_expected.to delegate_method(:parsed_rows).to(:store) }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to be_empty }
  end

  describe "#previous_step" do
    subject(:previous_step) { current_step.previous_step }

    it { is_expected.to eq(:csv) }
  end

  describe "#next_step" do
    subject(:next_step) { current_step.next_step }

    it { is_expected.to eq(:verify) }
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

      it "persists processed changes in the store" do
        expect { save! }
          .to change { current_step.store.processed_changes }
          .from(nil)
          .to([{ record_identifier: "Teacher(#1)", action: "destroy" }])
      end
    end

    context "when changes are not processed successfully" do
      let(:fake_changes) do
        instance_double(Admin::DataFixes::Changes, process: false)
      end

      it { is_expected.to be_falsey }

      it "does not persist processed changes in the store" do
        expect { save! }.not_to(change { current_step.store.processed_changes })
      end

      context "but there were processed changes already in the store" do
        let(:store) { FactoryBot.build(:session_repository, processed_changes:) }
        let(:processed_changes) do
          [{ record_identifier: "Teacher(#1)", action: "destroy" }]
        end

        it { is_expected.to be_falsey }

        it "clears the existing processed changes from the store" do
          expect { save! }
            .to change { current_step.store.processed_changes }
            .from([{ record_identifier: "Teacher(#1)", action: "destroy" }])
            .to(nil)
        end
      end
    end
  end
end
