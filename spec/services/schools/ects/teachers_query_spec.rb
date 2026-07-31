RSpec.describe Schools::ECTs::TeachersQuery do
  subject(:query) { described_class.new(school:, query_string:) }

  let(:school) { FactoryBot.create(:school) }
  let(:query_string) { nil }

  let(:search_double) { instance_double(Teachers::Search) }

  let!(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, :unfinished, school:)
  end
  let!(:induction_period) do
    FactoryBot.create(
      :induction_period,
      :unfinished,
      teacher: ect_at_school_period.teacher
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :unfinished,
      :with_expression_of_interest,
      :with_school_partnership,
      ect_at_school_period:
    )
  end
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, :unfinished, school:)
  end
  let!(:mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      :unfinished,
      mentee: ect_at_school_period,
      mentor: mentor_at_school_period
    )
  end

  describe "#teachers" do
    subject(:teachers) { query.teachers }

    it "calls `#search` on the `Teachers::Search` service with the correct parameters" do
      allow(Teachers::Search)
        .to receive(:new)
        .with(ect_at_school: school, in_progress: true, query_string:)
        .and_return(search_double)
      allow(search_double).to receive(:search).and_return(Teacher.all)

      teachers

      expect(search_double).to have_received(:search)
    end

    describe "preloading associations" do
      subject(:result) { teachers.first }

      it { expect(result.association(:ongoing_induction_period)).to be_loaded }
      it { expect(result.ongoing_induction_period.association(:appropriate_body_period)).to be_loaded }
      it { expect(result.association(:current_or_next_ect_at_school_period)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.association(:school)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.association(:school_reported_appropriate_body)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.association(:current_or_next_mentorship_period)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.current_or_next_mentorship_period.association(:mentor)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.current_or_next_mentorship_period.mentor.association(:teacher)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.association(:current_or_next_training_period)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.current_or_next_training_period.association(:lead_provider)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.current_or_next_training_period.association(:expression_of_interest)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.current_or_next_training_period.association(:expression_of_interest_lead_provider)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.current_or_next_training_period.association(:delivery_partner)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.association(:latest_training_period)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.latest_training_period.association(:lead_provider)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.latest_training_period.association(:expression_of_interest)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.latest_training_period.association(:expression_of_interest_lead_provider)).to be_loaded }
      it { expect(result.current_or_next_ect_at_school_period.latest_training_period.association(:delivery_partner)).to be_loaded }

      describe "lead provider name" do
        subject(:lead_provider_name) do
          result.current_or_next_ect_at_school_period.latest_lead_provider_name
        end

        context "when the teacher has a finished `TrainingPeriod`" do
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :finished,
              :with_expression_of_interest,
              :with_school_partnership,
              ect_at_school_period:
            )
          end

          it { is_expected.to eq(training_period.lead_provider_name) }
        end
      end
    end
  end

  describe "#total_teachers_count" do
    subject(:total_teachers_count) { query.total_teachers_count }

    it "calls `#count` on the `Teachers::Search` service with the correct parameters" do
      allow(Teachers::Search)
        .to receive(:new)
        .with(ect_at_school: school, in_progress: true)
        .and_return(search_double)
      allow(search_double).to receive(:count)

      total_teachers_count

      expect(search_double).to have_received(:count)
    end
  end
end
