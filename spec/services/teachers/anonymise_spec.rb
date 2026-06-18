RSpec.describe Teachers::Anonymise do
  subject(:service) { described_class.new(teacher:, reason: :registered_in_error) }

  let(:teacher) { FactoryBot.create(:teacher) }

  describe "#permitted?" do
    context "when the teacher has no induction periods or registrations" do
      it { is_expected.to be_permitted }
    end

    context "when the teacher has an induction period" do
      before { FactoryBot.create(:induction_period, teacher:) }

      it { is_expected.not_to be_permitted }
    end

    context "when the teacher has an ECT at school period" do
      before { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }

      it { is_expected.not_to be_permitted }
    end

    context "when the teacher has a mentor at school period" do
      before { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }

      it { is_expected.not_to be_permitted }
    end
  end

  describe "#anonymise!" do
    context "when permitted" do
      it "anonymises the teacher" do
        service.anonymise!
        teacher.reload

        expect(teacher.trs_first_name).to be_nil
        expect(teacher.trs_last_name).to be_nil
        expect(teacher.corrected_name).to be_nil
        expect(teacher.trn).to be_nil
        expect(teacher.trnless).to be(true)
      end

      it "sets the anonymisation reason" do
        service.anonymise!

        expect(teacher.reload.anonymisation_reason).to eq("registered_in_error")
      end

      it "sets anonymised_at" do
        freeze_time do
          service.anonymise!

          expect(teacher.reload.anonymised_at).to eq(Time.zone.now)
        end
      end

      it "preserves api ids" do
        original_api_id = teacher.api_id
        original_ect_id = teacher.api_ect_training_record_id
        original_mentor_id = teacher.api_mentor_training_record_id

        service.anonymise!
        teacher.reload

        expect(teacher.api_id).to eq(original_api_id)
        expect(teacher.api_ect_training_record_id).to eq(original_ect_id)
        expect(teacher.api_mentor_training_record_id).to eq(original_mentor_id)
      end
    end

    context "when not permitted" do
      before { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }

      it "raises NotPermittedError" do
        expect { service.anonymise! }.to raise_error(Teachers::Anonymise::NotPermittedError)
      end

      it "does not anonymise the teacher" do
        expect { service.anonymise! }.to raise_error(Teachers::Anonymise::NotPermittedError)
        teacher.reload

        expect(teacher.trs_first_name).to be_present
        expect(teacher.anonymisation_reason).to be_nil
        expect(teacher.anonymised_at).to be_nil
      end
    end
  end
end
