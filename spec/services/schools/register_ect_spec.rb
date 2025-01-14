describe Schools::RegisterECT do
  let(:first_name) { "Dusty" }
  let(:last_name) { "Rhodes" }
  let(:corrected_name) { "Randy Marsh" }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.yesterday }
  let(:working_pattern) { "full_time" }

  subject(:service) do
    described_class.new(first_name:,
                        last_name:,
                        trn:,
                        started_on:,
                        corrected_name:,
                        school:,
                        working_pattern:)
  end

  describe '#register_teacher!' do
    let(:teacher) { Teacher.first }
    let(:ect_at_school_period) { ECTAtSchoolPeriod.first }

    it 'creates a new Teacher record' do
      expect { service.register_teacher! }.to change(Teacher, :count).from(0).to(1)
      expect(teacher.first_name).to eq(first_name)
      expect(teacher.last_name).to eq(last_name)
      expect(teacher.trn).to eq(trn)
      expect(teacher.corrected_name).to eq(corrected_name)
    end

    it 'creates an associated ECTATSchoolPeriod record' do
      expect { service.register_teacher! }.to change(ECTAtSchoolPeriod, :count).from(0).to(1)
      expect(ect_at_school_period.teacher_id).to eq(teacher.id)
      expect(ect_at_school_period.started_on).to eq(started_on)
      expect(ect_at_school_period.working_pattern).to eq(working_pattern)
    end
  end
end
