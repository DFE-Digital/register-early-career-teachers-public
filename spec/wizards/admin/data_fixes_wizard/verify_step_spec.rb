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
  let(:params) { { note:, zendesk_ticket_id: } }
  let(:note) { "This is a note about the changes being made." }
  let(:zendesk_ticket_id) { "123456" }

  it { is_expected.to delegate_method(:processed_changes).to(:store) }

  describe ".permitted_params" do
    subject(:permitted_params) { described_class.permitted_params }

    it { is_expected.to contain_exactly(:zendesk_ticket_id, :note) }
  end

  describe "#previous_step" do
    subject(:previous_step) { current_step.previous_step }

    it { is_expected.to eq(:preview) }
  end

  describe "#next_step" do
    subject(:next_step) { current_step.next_step }

    it { is_expected.to eq(:confirmation) }
  end

  describe "validations" do
    context "when author is missing" do
      let(:author) { nil }

      it { is_expected.to have_error(:author, "can't be blank") }
    end

    context "when note and zendesk_ticket_id are both missing" do
      let(:note) { "" }
      let(:zendesk_ticket_id) { "" }

      it { is_expected.to have_error(:base, "Add a note or enter the Zendesk ticket number") }
    end

    context "when zendesk_ticket_id is not 6 digits" do
      let(:zendesk_ticket_id) { "1234" }

      it { is_expected.to have_error(:zendesk_ticket_id, "Ticket number must be 6 digits") }
    end

    context "when author and note are present" do
      let(:note) { "This is a note about the changes being made." }
      let(:zendesk_ticket_id) { "" }

      it { is_expected.to be_valid }
    end

    context "when author and zendesk_ticket_id are present" do
      let(:note) { "" }
      let(:zendesk_ticket_id) { "123456" }

      it { is_expected.to be_valid }
    end
  end

  describe "#save!" do
    subject(:save!) { current_step.save! }

    let(:fake_changes) do
      instance_double(
        Admin::DataFixes::Changes,
        process: saved_changes,
        errors: changes_errors
      )
    end

    before do
      allow(Admin::DataFixes::Changes).to receive(:new).and_return(fake_changes)
    end

    context "when the step is invalid" do
      let(:note) { "" }
      let(:zendesk_ticket_id) { "" }
      let(:saved_changes) { nil }
      let(:changes_errors) { [] }

      it { is_expected.to be_falsey }

      it "does not persist confirmed changes in the store" do
        expect { save! }.not_to(change { current_step.store.confirmed_changes })
      end

      it "does not record any events" do
        allow(Events::Record).to receive(:record_admin_data_fix_event!)

        save!

        expect(Events::Record).not_to have_received(:record_admin_data_fix_event!)
      end
    end

    context "when the step is valid and changes are processed successfully" do
      let(:saved_changes) do
        [
          {
            gid: "gid://app/teacher/1",
            action: "delete",
            changes: nil
          },
          {
            gid: "gid://app/teacher/2",
            action: "update",
            changes: { "something" => %w[old_value new_value] }
          },
        ]
      end
      let(:changes_errors) { [] }

      it { is_expected.to be_truthy }

      it "persists confirmed changes in the store" do
        expect { save! }
          .to change { current_step.store.confirmed_changes }
          .from(nil)
          .to(saved_changes)
      end

      it "records an event for each confirmed change" do
        allow(Events::Record).to receive(:record_admin_data_fix_event!)

        save!

        expect(Events::Record)
          .to have_received(:record_admin_data_fix_event!)
          .with(
            author:,
            body: note,
            zendesk_ticket_id:,
            modifications: nil,
            metadata: {
              gid: "gid://app/teacher/1",
              action: "delete",
              changes: nil
            }
          )
        expect(Events::Record)
          .to have_received(:record_admin_data_fix_event!)
          .with(
            author:,
            body: note,
            zendesk_ticket_id:,
            modifications: { "something" => %w[old_value new_value] },
            metadata: {
              gid: "gid://app/teacher/2",
              action: "update",
              changes: { "something" => %w[old_value new_value] }
            }
          )
      end
    end

    context "when the step is valid but changes are not processed successfully" do
      let(:saved_changes) { false }
      let(:changes_errors) do
        ActiveModel::Errors.new(instance_double(Admin::DataFixes::Changes)).tap do |errors|
          errors.add(:base, "Some changes could not be processed")
        end
      end

      it { is_expected.to be_falsey }

      it "adds errors from the changes object to the step's errors" do
        expect { save! }
          .to change { current_step.errors.added?(:base, "Some changes could not be processed") }
          .from(false).to(true)
          .and change { current_step.errors.added?(:base, "There was an error processing changes. All changes have been reverted.") }
          .from(false).to(true)
      end

      it "does not persist confirmed changes in the store" do
        expect { save! }.not_to(change { current_step.store.confirmed_changes })
      end

      it "does not record any events" do
        allow(Events::Record).to receive(:record_admin_data_fix_event!)

        save!

        expect(Events::Record).not_to have_received(:record_admin_data_fix_event!)
      end

      context "but there were confirmed changes already in the store" do
        let(:store) { FactoryBot.build(:session_repository, confirmed_changes:) }
        let(:confirmed_changes) do
          [{ gid: "gid://app/teacher/1", action: "destroy", changes: nil }]
        end

        it { is_expected.to be_falsey }

        it "clears the existing processed changes from the store" do
          expect { save! }
            .to change { current_step.store.confirmed_changes }
            .from([{ gid: "gid://app/teacher/1", action: "destroy", changes: nil }])
            .to(nil)
        end
      end
    end
  end
end
