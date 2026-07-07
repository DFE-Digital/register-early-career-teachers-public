RSpec.describe GIAS::Schools::Merge do
  describe "#merge!" do
    subject(:merge_school) { described_class.new(gias_school).merge! }

    let(:old_school) { gias_school.school }
    let(:new_school) { successor_gias_school.school }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :closed) }
    

    let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, :open) }

    let!(:school_link) { FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: gias_school, to_gias_school: successor_gias_school) }

    let(:teacher) { FactoryBot.create(:teacher) }

    let!(:old_mentor_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        teacher:,
        school: old_school,
        started_on: Date.new(2025, 1, 1),
        finished_on: Date.new(2025, 3, 31)
      )
    end

    let!(:new_mentor_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        teacher:,
        school: new_school,
        started_on: Date.new(2025, 3, 1),
        finished_on: Date.new(2025, 6, 30)
      )
    end

    let!(:ect_period) { FactoryBot.create(:ect_at_school_period, school: old_school) }

    before do
      allow(gias_school).to receive(:can_be_merged?).and_return(true)
    end

    it "merges overlapping mentor periods and moves remaining periods to the successor school" do
      expect { merge_school }
        .to change(MentorAtSchoolPeriod, :count).by(-1)

      expect(merge_school).to be(true)

      expect(new_mentor_period.reload).to have_attributes(
        school: new_school,
        started_on: Date.new(2025, 1, 1),
        finished_on: Date.new(2025, 6, 30)
      )

      expect { old_mentor_period.reload }
        .to raise_error(ActiveRecord::RecordNotFound)

      expect(ect_period.reload.school).to eq(new_school)
    end
  end
end
