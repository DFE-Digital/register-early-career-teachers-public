describe ECTAtSchoolPeriods::TextSearch do
  # Given some schools..
  let!(:grange_hill_school) { FactoryBot.create(:school) }
  let!(:bash_street_school) { FactoryBot.create(:school) }

  # Some teachers..
  let!(:postman_pat) { FactoryBot.create(:teacher, trn: "1234567", trs_first_name: "Postman", trs_last_name: "Pat") }
  let!(:bob_builder) { FactoryBot.create(:teacher, trn: "2345678", trs_first_name: "Bob", trs_last_name: "Builder") }
  let!(:bob_squarepants) { FactoryBot.create(:teacher, trn: "3456789", trs_first_name: "Bob", trs_last_name: "Squarepants") }

  # And some AtSchoolPeriods..
  let!(:pat_at_grange_hill) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: postman_pat, school: grange_hill_school) }
  let!(:bob_builder_at_grange_hill) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: bob_builder, school: grange_hill_school) }
  let!(:bob_squarepants_at_bash_street) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: bob_squarepants, school: bash_street_school) }

  describe "#search" do
    subject(:search) { described_class.new(initial_cohort, query_string:).search }

    let(:initial_cohort) { ECTAtSchoolPeriod.all }

    context "when the query string is blank" do
      let(:query_string) { "" }

      it { is_expected.to match(initial_cohort) }
    end

    context "when the query string is nil" do
      let(:query_string) { nil }

      it { is_expected.to match(initial_cohort) }
    end

    context "when the query string contains a 7-digit TRN" do
      let(:query_string) { "1234567" }

      it { is_expected.to contain_exactly(pat_at_grange_hill) }
    end

    context "when the query string contains multiple 7-digit TRNs" do
      let(:query_string) { "1234567 2345678" }

      it { is_expected.to contain_exactly(pat_at_grange_hill, bob_builder_at_grange_hill) }
    end

    context "when the query string contains text" do
      let(:query_string) { "Bob" }

      it { is_expected.to contain_exactly(bob_builder_at_grange_hill, bob_squarepants_at_bash_street) }

      context "when the initial cohort is pre-filtered" do
        let(:initial_cohort) { ECTAtSchoolPeriod.all.with_teacher.joins(:teacher).where(school: grange_hill_school) }

        it { is_expected.to contain_exactly(bob_builder_at_grange_hill) }
      end
    end
  end
end
