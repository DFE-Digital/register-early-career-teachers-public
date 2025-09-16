RSpec.describe Participants::Query do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  describe "#participants" do
    subject(:participants) { described_class.new(lead_provider:).participants }

    context "when there are both ECT and mentor training periods for the lead provider" do
      let!(:ect_teacher) { FactoryBot.create(:teacher) }
      let!(:mentor_teacher) { FactoryBot.create(:teacher) }
      let!(:both_teacher) { FactoryBot.create(:teacher) }

      let!(:school_partnership) do
        FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
      end
      let!(:lead_provider_delivery_partnership) do
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
      end
      let!(:active_lead_provider) do
        FactoryBot.create(:active_lead_provider, lead_provider:)
      end

      before do
        # ECT only
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, teacher: ect_teacher)
        FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                          ect_at_school_period:,
                          school_partnership:,
                          started_on: ect_at_school_period.started_on,
                          finished_on: ect_at_school_period.finished_on)

        # Mentor only
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher)
        FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                          mentor_at_school_period:,
                          school_partnership:,
                          started_on: mentor_at_school_period.started_on,
                          finished_on: mentor_at_school_period.finished_on)

        # Both ECT and mentor
        both_ect_period = FactoryBot.create(:ect_at_school_period, teacher: both_teacher)
        both_mentor_period = FactoryBot.create(:mentor_at_school_period, teacher: both_teacher)
        FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                          ect_at_school_period: both_ect_period,
                          school_partnership:,
                          started_on: both_ect_period.started_on,
                          finished_on: both_ect_period.finished_on)
        FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                          mentor_at_school_period: both_mentor_period,
                          school_partnership:,
                          started_on: both_mentor_period.started_on,
                          finished_on: both_mentor_period.finished_on)
      end

      it "returns all teachers without duplicates" do
        expect(participants).to contain_exactly(ect_teacher, mentor_teacher, both_teacher)
      end

      it "includes teacher who is both ECT and mentor only once" do
        expect(participants.where(id: both_teacher.id).count).to eq(1)
      end
    end
  end
end
