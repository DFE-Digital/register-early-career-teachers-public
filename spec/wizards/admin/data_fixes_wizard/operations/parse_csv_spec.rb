RSpec.describe Admin::DataFixesWizard::Operations::ParseCSV do
  subject(:instance) do
    described_class.new(repository:, step: wizard.current_step)
  end

  let!(:wizard) do
    Admin::DataFixesWizard::Wizard.new(
      current_step: :csv,
      current_step_params: ActionController::Parameters.new(csv: { csv_string: }),
      state_store:
    )
  end
  let(:state_store) { Admin::DataFixesWizard::StateStore.new(repository:) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  describe "#execute" do
    subject(:execute) { instance.execute }

    context "when the CSV is formatted correctly with the expected headers" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,attributes
          something,1,create,"attribute1,value1,attribute2,value2"
          another_thing,2,destroy,""
        ROWS
      end

      it "writes parsed rows to the step" do
        expect { execute }
          .to change(wizard.current_step, :parsed_rows)
          .from(nil)
          .to([
            {
              "object_type" => "something",
              "object_id" => "1",
              "action" => "create",
              "attributes" => "attribute1,value1,attribute2,value2"
            },
            {
              "object_type" => "another_thing",
              "object_id" => "2",
              "action" => "destroy",
              "attributes" => ""
            }
          ])
      end

      it "is successful" do
        expect(execute[:success]).to be_truthy
      end

      it "returns no errors" do
        expect(execute[:errors]).to be_nil
      end
    end

    context "when the CSV has no headers" do
      let(:csv_string) do
        <<~ROWS
          something,1,create,"attribute1,value1,attribute2,value2"
          anotherthing,2,destroy,""
        ROWS
      end

      it "writes parsed rows to the step" do
        expect { execute }.not_to change(wizard.current_step, :parsed_rows)
      end

      it "is not successful" do
        expect(execute[:success]).to be_falsey
      end

      it "adds errors to the step" do
        expect { execute }
          .to change { wizard.current_step.errors.messages }
          .from({})
          .to({ csv_string: ["CSV has invalid headers"] })
      end

      it "returns errors" do
        expect(execute[:errors].messages)
          .to eq({ csv_string: ["CSV has invalid headers"] })
      end
    end

    context "when the CSV has missing headers" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,attributes
          something,1,create,"attribute1,value1,attribute2,value2"
          anotherthing,2,destroy,""
        ROWS
      end

      it "writes parsed rows to the step" do
        expect { execute }.not_to change(wizard.current_step, :parsed_rows)
      end

      it "is not successful" do
        expect(execute[:success]).to be_falsey
      end

      it "adds errors to the step" do
        expect { execute }
          .to change { wizard.current_step.errors.messages }
          .from({})
          .to({ csv_string: ["CSV has invalid headers"] })
      end

      it "returns errors" do
        expect(execute[:errors].messages)
          .to eq({ csv_string: ["CSV has invalid headers"] })
      end
    end

    context "when the CSV has the wrong headers" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,wrong_header
          something,1,create,"attribute1,value1,attribute2,value2"
          anotherthing,2,destroy,""
        ROWS
      end

      it "writes parsed rows to the step" do
        expect { execute }.not_to change(wizard.current_step, :parsed_rows)
      end

      it "is not successful" do
        expect(execute[:success]).to be_falsey
      end

      it "adds errors to the step" do
        expect { execute }
          .to change { wizard.current_step.errors.messages }
          .from({})
          .to({ csv_string: ["CSV has invalid headers"] })
      end

      it "returns errors" do
        expect(execute[:errors].messages)
          .to eq({ csv_string: ["CSV has invalid headers"] })
      end
    end

    context "when the CSV is malformed" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,attributes
          something,1,create,"unterminated,string
        ROWS
      end

      it "writes parsed rows to the step" do
        expect { execute }.not_to change(wizard.current_step, :parsed_rows)
      end

      it "is not successful" do
        expect(execute[:success]).to be_falsey
      end

      it "adds errors to the step" do
        expect { execute }
          .to change { wizard.current_step.errors.messages }
          .from({})
          .to({ csv_string: ["CSV is malformed"] })
      end

      it "returns errors" do
        expect(execute[:errors].messages)
          .to eq({ csv_string: ["CSV is malformed"] })
      end
    end
  end
end
