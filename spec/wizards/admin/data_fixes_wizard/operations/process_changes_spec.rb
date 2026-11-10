RSpec.describe Admin::DataFixesWizard::Operations::ProcessChanges do
  subject(:instance) do
    described_class.new(repository:, step: wizard.current_step)
  end

  let!(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :preview,
      current_step_params: ActionController::Parameters.new(preview: {}),
      state_store:
    )
  end
  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  describe "#execute" do
    subject(:execute) { instance.execute }

    let(:parsed_rows) do
      [{ "test" => "something" }, { "test" => "another_thing" }]
    end
    let(:fake_changes) do
      instance_double(
        Admin::DataFixes::Changes,
        valid?: changes_valid?,
        results: changes_results,
        errors: changes_errors
      )
    end

    before do
      state_store.write(parsed_rows:)
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

      it "writes changes to the step" do
        expect { execute }
          .to change(wizard.current_step, :processed_changes)
          .from(nil)
          .to([deleted_teacher_change, updated_teacher_change])
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
        expect { execute }.not_to change(wizard.current_step, :processed_changes)
      end

      it "is not successful" do
        expect(execute[:success]).to be_falsey
      end

      it "adds errors to the step" do
        expect { execute }
          .to change { wizard.current_step.errors.full_messages }
          .from([])
          .to(["Some changes could not be processed"])
      end

      it "returns errors" do
        expect(execute[:errors].full_messages)
          .to eq(["Some changes could not be processed"])
      end

      context "when there are existing processed changes" do
        before do
          state_store.write(processed_changes: [deleted_teacher_change])
        end

        it "clears the previous processed changes" do
          expect { execute }
            .to change(state_store, :processed_changes)
            .from([deleted_teacher_change])
            .to(nil)
        end
      end
    end
  end
end
