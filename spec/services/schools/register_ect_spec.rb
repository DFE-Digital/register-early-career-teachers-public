RSpec.describe Schools::RegisterECT do
  subject(:service) do
    described_class.new(appropriate_body:,
                        corrected_name:,
                        email:,
                        lead_provider:,
                        programme_type:,
                        school:,
                        started_on:,
                        trn:,
                        trs_first_name:,
                        trs_last_name:,
                        working_pattern:)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:corrected_name) { "Randy Marsh" }
  let(:email) { "randy@tegridyfarms.com" }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:programme_type) { 'provider_led' }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.yesterday }
  let(:trn) { "3002586" }
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:working_pattern) { "full_time" }

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
        expect { service.register! }.not_to change(Teacher, :count)
      end
    end

    context "when a Teacher record with the same trn exists and has ect records" do
      let(:teacher) { FactoryBot.create(:teacher, trn:) }

      before { FactoryBot.create(:ect_at_school_period, teacher:) }

      it "raise an exception" do
        expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'creates an associated ECTATSchoolPeriod record' do
      expect { service.register! }.to change(ECTAtSchoolPeriod, :count).from(0).to(1)
      expect(ect_at_school_period.teacher_id).to eq(Teacher.first.id)
      expect(ect_at_school_period.started_on).to eq(started_on)
      expect(ect_at_school_period.working_pattern).to eq(working_pattern)
      expect(ect_at_school_period.email).to eq(email)
      expect(ect_at_school_period.appropriate_body_id).to eq(appropriate_body.id)
      expect(ect_at_school_period.lead_provider_id).to eq(lead_provider.id)
      expect(ect_at_school_period.programme_type).to eq(programme_type)
    end

    it 'sets ab and provider choices for the school' do
      expect { service.register! }
        .to change(school, :chosen_appropriate_body_id)
              .to(appropriate_body.id)
              .and change(school, :chosen_programme_type)
                     .to(programme_type)
                     .and change(school, :chosen_lead_provider_id).to(lead_provider.id)
    end
  end
end
