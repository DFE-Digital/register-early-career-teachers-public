describe Schools::RegisterMentor do
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:corrected_name) { "Randy Marsh" }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.yesterday }

  subject(:service) do
    described_class.new(trs_first_name:,
                        trs_last_name:,
                        corrected_name:,
                        trn:,
                        school_urn: school.urn,
                        started_on:)
  end

  describe '#call' do
    let(:teacher) { Teacher.first }
    let(:mentor_at_school_period) { MentorAtSchoolPeriod.first }

    it 'creates a new Teacher record' do
      expect { service.register! }.to change(Teacher, :count).from(0).to(1)
      expect(teacher.trs_first_name).to eq(trs_first_name)
      expect(teacher.trs_last_name).to eq(trs_last_name)
      expect(teacher.corrected_name).to eq(corrected_name)
      expect(teacher.trn).to eq(trn)
    end

    it 'creates an associated MentorATSchoolPeriod record' do
      expect { service.register! }.to change(MentorAtSchoolPeriod, :count).from(0).to(1)
      expect(mentor_at_school_period.teacher_id).to eq(teacher.id)
      expect(mentor_at_school_period.started_on).to eq(started_on)
    end

    context "when no start date is provided" do
      subject(:service) do
        described_class.new(trs_first_name:,
                            trs_last_name:,
                            corrected_name:,
                            trn:,
                            school_urn: school.urn)
      end

      it "current date is assigned" do
        service.register!

        expect(mentor_at_school_period.started_on).to eq(Date.current)
      end
    end
  end
end
