describe ECF1TeacherHistory::DataPatcher do
  subject(:patcher) { described_class.new(data_patches:) }

  let(:headers) do
    %i[
      participant_profile_id
      induction_record_id
      delete_record
      start_date
      end_date
      created_at
      updated_at
      email
      mentor_profile_id
      training_status
      induction_status
      school_transfer
      state_type
      state_reason
      state_cpd_lead_provider_id
      state_created_at
      ignore_training
      date_added
      added_by
      reason
    ]
  end

  let(:data_patches) do
    CSV.parse(row_data, headers:)
  end

  let(:row_data) { "" }

  let(:data_patch_ect_id) { "91f69d37-deec-473e-a150-b939c0b9fd97" }
  let(:data_patch_ect_ir_id) { "89b2626c-ee4c-49a9-af8e-2fd933e5d3f0" }
  let(:data_patch_mentor_id) { "bf0415d1-948a-444f-a5f9-23661f8db6ce" }
  let(:data_patch_ect_with_state_id) { "8237fd2e-2c3c-4daa-a5d7-2bab689e66a7" }

  let(:ect) { nil }
  let(:mentor) { nil }
  let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, ect:, mentor:) }

  describe "#apply_patches_to" do
    context "when there are no patches to apply" do
      it "returns the original teacher history unchanged" do
        expect(patcher.apply_patches_to(ecf1_teacher_history)).to eq(ecf1_teacher_history)
      end
    end

    context "changes to an induction record" do
      subject(:patched_result) { described_class.new(data_patches:).apply_patches_to(ecf1_teacher_history) }

      let(:new_email) { "scoob@example.com" }
      let(:mentor_profile_id) { "1fce1a06-d889-4527-a1a1-cbedda7f5194" }

      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id, induction_records:) }
      let(:induction_record_1) do
        FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                         start_date: Date.new(2204, 9, 1),
                         induction_record_id: data_patch_ect_ir_id)
      end
      let(:induction_record_2) do
        FactoryBot.build(:ecf1_teacher_history_induction_record_row)
      end

      let(:induction_records) { [induction_record_1, induction_record_2] }

      context "delete_record is set" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},true,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "removes the induction record from the profile" do
          expect(patched_result.ect.induction_records.find { |ir| ir.induction_record_id == data_patch_ect_ir_id }).to be_nil
        end
      end

      context "start_date has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,2024-9-1,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the start_date to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.start_date).to eq(Date.new(2024, 9, 1))
        end
      end

      context "end_date has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,2025-11-10,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the end_date to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.end_date).to eq(Date.new(2025, 11, 10))
        end
      end

      context "end_date has a :null value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,:null,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the end_date to be nil" do
          expect(patched_result.ect.induction_records.first.end_date).to be_nil
        end
      end

      context "created_at has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,"2024-09-01 12:22:54",,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the created_at to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.created_at).to eq(Time.zone.local(2024, 9, 1, 12, 22, 54))
        end
      end

      context "updated_at has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,"2024-09-06 21:42:54",,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the updated_at to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.updated_at).to eq(Time.zone.local(2024, 9, 6, 21, 42, 54))
        end
      end

      context "email has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,"#{new_email}",,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the email to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.preferred_identity_email).to eq(new_email)
        end
      end

      context "mentor_profile_id has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,,"#{mentor_profile_id}",,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the mentor_profile_id to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.mentor_profile_id).to eq(mentor_profile_id)
        end
      end

      context "training_status has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,,,"deferred",,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the training_status to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.training_status).to eq("deferred")
        end
      end

      context "induction_status has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,,,,"withdrawn",,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the induction_status to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.induction_status).to eq("withdrawn")
        end
      end

      context "school_transfer has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,,,,,"true",,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "changes the school_transfer to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.school_transfer).to be(true)
        end
      end

      context "ignore_training is not set" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

        it "does not set the ignore_training flag in the record" do
          expect(patched_result.ect.induction_records.first).not_to be_ignore_training
        end
      end

      context "ignore_training has a value" do
        let(:row_data) { %("#{data_patch_ect_id}",#{data_patch_ect_ir_id},,,,,,,,,,,,,,,true,12/05/2025,Big Jeff,fixes issue) }

        it "changes the ignore_training flag to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first).to be_ignore_training
        end
      end
    end

    context "adding a state" do
      subject(:patched_result) { described_class.new(data_patches:).apply_patches_to(ecf1_teacher_history) }

      let(:row_data) { %("8237fd2e-2c3c-4daa-a5d7-2bab689e66a7",,,,,,,,,,,,"withdrawn","switched-to-school-led","22727fdc-816a-4a3c-9675-030e724bbf89","2024-10-01 12:15:01",,12/05/2025,Big Jeff,fixes issue) }
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_with_state_id) }

      it "adds a new state with the details from the CSV" do
        expect(patched_result.ect.states.count).to eq(2)

        new_state = patched_result.ect.states.find { |state| state.state == "withdrawn" }
        expect(new_state.reason).to eq("switched-to-school-led")
        expect(new_state.cpd_lead_provider_id).to eq("22727fdc-816a-4a3c-9675-030e724bbf89")
        expect(new_state.created_at).to eq(Time.zone.local(2024, 10, 1, 12, 15, 1))
      end
    end
  end

  describe "#has_patches?" do
    context "when the history has neither profile" do
      it "returns false" do
        expect(patcher).not_to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has an ect profile that matches rows in the CSV" do
      let(:row_data) { %("#{data_patch_ect_id}",,,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id) }

      it "returns true" do
        expect(patcher).to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has an ect profile that does not match rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect) }

      it "returns false" do
        expect(patcher).not_to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has a mentor profile that matches rows in the CSV" do
      let(:row_data) { %("#{data_patch_mentor_id}",,,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, participant_profile_id: data_patch_mentor_id) }

      it "returns true" do
        expect(patcher).to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has a mentor profile that does not match rows in the CSV" do
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor) }

      it "returns false" do
        expect(patcher).not_to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has ect and mentor profile that both match rows in the CSV" do
      let(:row_data) { %("#{data_patch_ect_id}",,,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue\n"#{data_patch_mentor_id}",,,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, participant_profile_id: data_patch_mentor_id) }

      it "returns true" do
        expect(patcher).to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has ect and mentor profile and the ect matches rows in the CSV" do
      let(:row_data) { %("#{data_patch_ect_id}",,,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor) }

      it "returns true" do
        expect(patcher).to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has ect and mentor profiles and the mentor matches rows in the CSV" do
      let(:row_data) { %("#{data_patch_mentor_id}",,,,,,,,,,,,,,,,,12/05/2025,Big Jeff,fixes issue) }

      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, participant_profile_id: data_patch_mentor_id) }

      it "returns true" do
        expect(patcher).to have_patches(ecf1_teacher_history)
      end
    end

    context "when the history has ect and mentor profile that do not match rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor) }

      it "returns false" do
        expect(patcher).not_to have_patches(ecf1_teacher_history)
      end
    end
  end
end
