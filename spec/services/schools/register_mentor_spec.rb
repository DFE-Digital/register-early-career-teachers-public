describe Schools::RegisterMentor do
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:corrected_name) { "Randy Marsh" }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:email) { "randy@tegridyfarms.com" }
  let(:started_on) { Date.yesterday }

  subject(:service) do
    described_class.new(trs_first_name:,
                        trs_last_name:,
                        corrected_name:,
                        trn:,
                        school_urn: school.urn,
                        email:,
                        started_on:)
  end

  describe '#call' do
    let(:mentor_at_school_period) { MentorAtSchoolPeriod.first }

    context "when a Teacher record with the same trn don't exist" do
      let(:teacher) { Teacher.first }

      it 'creates a new Teacher record' do
        expect { service.register! }.to change(Teacher, :count).from(0).to(1)
        expect(teacher.trs_first_name).to eq(trs_first_name)
        expect(teacher.trs_last_name).to eq(trs_last_name)
        expect(teacher.corrected_name).to eq(corrected_name)
        expect(teacher.trn).to eq(trn)
      end
    end

    context "when a Teacher record with the same trn exists but has no mentor records" do
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }

      it "doesn't create a new Teacher record" do
        expect { service.register! }.to_not change(Teacher, :count)
      end
    end

    context "when a Teacher record with the same trn exists and has mentor records" do
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }
      let!(:mentor) { FactoryBot.create(:mentor_at_school_period, teacher:) }

      it "raise an exception" do
        expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'creates an associated MentorATSchoolPeriod record' do
      expect { service.register! }.to change(MentorAtSchoolPeriod, :count).from(0).to(1)
      expect(mentor_at_school_period.teacher_id).to eq(Teacher.first.id)
      expect(mentor_at_school_period.started_on).to eq(started_on)
      expect(mentor_at_school_period.email).to eq(email)
    end

    context "when no start date is provided" do
      subject(:service) do
        described_class.new(trs_first_name:,
                            trs_last_name:,
                            corrected_name:,
                            trn:,
                            school_urn: school.urn,
                            email:)
      end

      it "current date is assigned" do
        service.register!

        expect(mentor_at_school_period.started_on).to eq(Date.current)
      end
    end
  end
end
