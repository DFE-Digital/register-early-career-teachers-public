describe Schools::RegisterECT do
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:corrected_name) { "Randy Marsh" }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.yesterday }
  let(:working_pattern) { "full_time" }

  subject(:service) do
    described_class.new(trs_first_name:,
                        trs_last_name:,
                        trn:,
                        started_on:,
                        corrected_name:,
                        school:,
                        working_pattern:)
  end

  describe '#register!' do
    let(:ect_at_school_period) { ECTAtSchoolPeriod.first }

    context "when a Teacher record with the same trn don't exist" do
      let(:teacher) { Teacher.first }

      it 'creates a new Teacher record' do
        expect { service.register! }.to change(Teacher, :count).from(0).to(1)
        expect(teacher.trs_first_name).to eq(trs_first_name)
        expect(teacher.trs_last_name).to eq(trs_last_name)
        expect(teacher.trn).to eq(trn)
        expect(teacher.corrected_name).to eq(corrected_name)
      end
    end

    context "when a Teacher record with the same trn exists but has no ect records" do
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }

      it "doesn't create a new Teacher record" do
        expect { service.register! }.to_not change(Teacher, :count)
      end
    end

    context "when a Teacher record with the same trn exists and has ect records" do
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }
      let!(:mentor) { FactoryBot.create(:ect_at_school_period, teacher:) }

      it "raise an exception" do
        expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'creates an associated ECTATSchoolPeriod record' do
      expect { service.register! }.to change(ECTAtSchoolPeriod, :count).from(0).to(1)
      expect(ect_at_school_period.teacher_id).to eq(Teacher.first.id)
      expect(ect_at_school_period.started_on).to eq(started_on)
      expect(ect_at_school_period.working_pattern).to eq(working_pattern)
    end
  end
end
