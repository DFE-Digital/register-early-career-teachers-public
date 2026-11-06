RSpec.describe Admin::DataFixesWizard::Operations::ConfirmChanges do
  subject(:instance) do
    described_class.new(repository:, step: wizard.current_step)
  end

  let!(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :verify,
      current_step_params: ActionController::Parameters.new(verify: params),
      state_store:
    )
  end
  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  let(:params) { { note: "This is a test note", zendesk_ticket_id: "123456" } }
  let(:current_user) { FactoryBot.create(:dfe_user, role: "product_team") }

  let(:parsed_rows) do
    [{ "test" => "something" }, { "test" => "another_thing" }]
  end

  before do
    state_store.write(parsed_rows:)
    allow(wizard).to receive(:author).and_return(current_user)
  end

  describe "#execute" do
    subject(:execute) { instance.execute }

    let(:fake_changes) do
      instance_double(
        Admin::DataFixes::Changes,
        valid?: changes_valid?,
        results: changes_results,
        errors: changes_errors
      )
    end

    before do
      allow(Admin::DataFixes::Changes)
        .to receive(:new)
        .with(parsed_rows:)
        .and_return(fake_changes)
    end

    context "when the changes are valid" do
      let(:changes_valid?) { true }

      let!(:deleted_teacher) { FactoryBot.create(:teacher) }
      let!(:updated_teacher) { FactoryBot.create(:teacher) }
      let(:deleted_teacher_change) do
        {
          gid: deleted_teacher.to_global_id.to_s,
          action: "delete",
          changes: {}
        }
      end
      let(:updated_teacher_change) do
        {
          gid: updated_teacher.to_global_id.to_s,
          action: "update",
          changes: { "something" => %w[old_value new_value] }
        }
      end

      let(:changes_results) do
        [
          instance_double(
            Admin::DataFixes::Processor::Result,
            target_object: deleted_teacher,
            action: "delete",
            error: nil,
            success?: true,
            saved_change: deleted_teacher_change
          ),
          instance_double(
            Admin::DataFixes::Processor::Result,
            target_object: updated_teacher,
            action: "update",
            error: nil,
            success?: true,
            saved_change: updated_teacher_change
          ),
        ]
      end
      let(:changes_errors) do
        ActiveModel::Errors.new(instance_double(Admin::DataFixes::Changes))
      end

      before { deleted_teacher.destroy! }

      it "writes changes to the step" do
        expect { execute }
          .to change(wizard.current_step, :confirmed_changes)
          .from(nil)
          .to([deleted_teacher_change, updated_teacher_change])
      end

      it "records an event for each change" do
        events = Event.where(event_type: "admin_data_fix").order(:id)
        expect { execute }.to change(events, :count).from(0).to(2)

        expect(events.map(&:body).uniq)
          .to contain_exactly(params[:note])
        expect(events.map(&:zendesk_ticket_id).uniq)
          .to contain_exactly(params[:zendesk_ticket_id].to_i)

        expect(events.first).to have_attributes(
          teacher_id: nil,
          modifications: [],
          metadata: deleted_teacher_change.as_json
        )
        expect(events.second).to have_attributes(
          teacher_id: updated_teacher.id,
          modifications: ["Something changed from 'old_value' to 'new_value'"],
          metadata: updated_teacher_change.as_json
        )
      end

      it "is successful" do
        expect(execute[:success]).to be_truthy
      end

      it "returns no errors" do
        expect(execute[:errors]).to be_nil
      end
    end

    context "when the changes are not valid" do
      let(:changes_valid?) { false }

      let!(:deleted_teacher) { FactoryBot.create(:teacher) }
      let!(:updated_teacher) { FactoryBot.create(:teacher) }
      let(:deleted_teacher_change) do
        {
          gid: deleted_teacher.to_global_id.to_s,
          action: "delete",
          changes: {}
        }
      end
      let(:updated_teacher_change) { nil }

      let(:changes_results) do
        [
          instance_double(
            Admin::DataFixes::Processor::Result,
            target_object: deleted_teacher,
            action: "delete",
            error: nil,
            success?: true,
            saved_change: deleted_teacher_change
          ),
          instance_double(
            Admin::DataFixes::Processor::Result,
            target_object: updated_teacher,
            action: "update",
            error: "There was an error",
            success?: false,
            saved_change: updated_teacher_change
          ),
        ]
      end
      let(:changes_errors) do
        ActiveModel::Errors.new(instance_double(Admin::DataFixes::Changes)).tap do |errors|
          errors.add(:base, "Some changes could not be processed")
        end
      end

      it "does not write changes to the step" do
        expect { execute }.not_to change(wizard.current_step, :confirmed_changes)
      end

      it "does not record any events" do
        events = Event.where(event_type: "admin_data_fix")
        expect { execute }.not_to change(events, :count)
      end

      it "is not successful" do
        expect(execute[:success]).to be_falsey
      end

      it "adds errors to the step" do
        expect { execute }
        .to change { wizard.current_step.errors.full_messages }
        .from([])
        .to([
          "There was an error processing changes. All changes have been reverted.",
          "Some changes could not be processed"
        ])
      end

      it "returns errors" do
        expect(execute[:errors].full_messages).to eq([
          "There was an error processing changes. All changes have been reverted.",
          "Some changes could not be processed"
        ])
      end

      context "when there are existing confirmed changes" do
        before do
          state_store.write(confirmed_changes: [deleted_teacher_change])
        end

        it "clears the previous confirmed changes" do
          expect { execute }
            .to change(state_store, :confirmed_changes)
            .from([deleted_teacher_change])
            .to(nil)
        end
      end
    end
  end
end
