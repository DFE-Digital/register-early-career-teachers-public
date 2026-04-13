describe ECF1TeacherHistory::DataPatcher do
  subject(:patcher) { described_class.new(csv_file: file_fixture("data_patches.csv")) }

  let(:data_patch_ect_id) { "91f69d37-deec-473e-a150-b939c0b9fd97" }
  let(:data_patch_ect_ir_id) { "89b2626c-ee4c-49a9-af8e-2fd933e5d3f0" }
  let(:data_patch_mentor_id) { "bf0415d1-948a-444f-a5f9-23661f8db6ce" }

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

      subject(:patched_result) { described_class.new(csv_file: file_fixture("data_patches.csv")).apply_patches_to(ecf1_teacher_history) }

      context "start_date has a value" do
        it "changes the start_date to match the value in the CSV" do
          expect(patched_result.ect.induction_records.first.start_date).to eq(Date.new(2024, 9, 1))
        end
      end
    end
  end

  describe "#has_patches?" do
    context "when the history has neither profile" do
      it "returns false" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_falsey
      end
    end

    context "when the history has an ect profile that matches rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id) }

      it "returns true" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_truthy
      end
    end

    context "when the history has an ect profile that does not match rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect) }

      it "returns false" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_falsey
      end
    end

    context "when the history has a mentor profile that matches rows in the CSV" do
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, participant_profile_id: data_patch_mentor_id) }

      it "returns true" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_truthy
      end
    end

    context "when the history has a mentor profile that does not match rows in the CSV" do
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor) }

      it "returns false" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_falsey
      end
    end

    context "when the history has ect and mentor profile that both match rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, participant_profile_id: data_patch_mentor_id) }

      it "returns true" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_truthy
      end
    end

    context "when the history has ect and mentor profile and the ect matches rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, participant_profile_id: data_patch_ect_id) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor) }

      it "returns true" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_truthy
      end
    end

    context "when the history has ect and mentor profiles and the mentor matches rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, participant_profile_id: data_patch_mentor_id) }

      it "returns true" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_truthy
      end
    end

    context "when the history has ect and mentor profile that do not match rows in the CSV" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect) }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor) }

      it "returns false" do
        expect(patcher.has_patches?(ecf1_teacher_history)).to be_falsey
      end
    end
  end
end
