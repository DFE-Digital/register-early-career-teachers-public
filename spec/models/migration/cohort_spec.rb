describe Migration::Cohort, type: :model do
  subject { create(:migration_cohort) }

  describe "#next" do
    let!(:next_cohort) { create(:migration_cohort, start_year: subject.start_year + 1) }

    it "returns the next cohort of the given cohort" do
      expect(subject.next).to eq(next_cohort)
    end
  end
end
