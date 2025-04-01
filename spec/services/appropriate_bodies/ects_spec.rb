RSpec.describe AppropriateBodies::ECTs do
  subject { AppropriateBodies::ECTs.new(appropriate_body) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  describe "#current_or_completed_while_at_appropriate_body" do
    context 'when the latest induction period is with this appropriate body' do
      let!(:earlier_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body: other_appropriate_body,
                          started_on: 1.year.ago,
                          finished_on: 6.months.ago,
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      let!(:latest_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          started_on: 6.months.ago,
                          finished_on: 1.month.ago,
                          outcome: 'pass',
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      it 'includes the teacher' do
        expect(subject.current_or_completed_while_at_appropriate_body).to include(teacher)
      end
    end

    context 'when the latest induction period is with another appropriate body' do
      let!(:earlier_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          started_on: 1.year.ago,
                          finished_on: 6.months.ago,
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      let!(:latest_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body: other_appropriate_body,
                          started_on: 6.months.ago,
                          finished_on: 1.month.ago,
                          outcome: 'pass', # pass or fail should be on last IP
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      it 'excludes the teacher' do
        expect(subject.current_or_completed_while_at_appropriate_body).not_to include(teacher)
      end
    end

    context 'when the teacher has an ongoing induction period with this appropriate body' do
      let!(:earlier_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body: other_appropriate_body,
                          started_on: 1.year.ago,
                          finished_on: 6.months.ago,
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      let!(:ongoing_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          started_on: 6.months.ago,
                          finished_on: nil,
                          number_of_terms: nil,
                          induction_programme: 'fip')
      end

      it 'includes the teacher' do
        expect(subject.current_or_completed_while_at_appropriate_body).to include(teacher)
      end
    end

    context 'when the teacher has a failed outcome with this appropriate body' do
      let!(:earlier_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          started_on: 1.year.ago,
                          finished_on: 6.months.ago,
                          outcome: 'pass',
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      let!(:failed_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          started_on: 6.months.ago,
                          finished_on: 1.month.ago,
                          outcome: 'fail',
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      it 'includes the teacher' do
        expect(subject.current_or_completed_while_at_appropriate_body).to include(teacher)
      end
    end

    context 'when the teacher has a finished induction period with no outcome' do
      let!(:induction_period_without_outcome) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          started_on: 6.months.ago,
                          finished_on: 1.month.ago,
                          outcome: nil,
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      it 'excludes the teacher' do
        expect(subject.current_or_completed_while_at_appropriate_body).not_to include(teacher)
      end
    end
  end

  describe "#former" do
    context 'when the teacher has a finished induction period' do
      let!(:finished_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          finished_on: 1.month.ago,
                          number_of_terms: 3,
                          induction_programme: 'fip')
      end

      it 'includes the teacher' do
        expect(subject.former).to include(teacher)
      end
    end

    context 'when the teacher has an ongoing induction period' do
      let!(:ongoing_induction_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          appropriate_body:,
                          finished_on: nil,
                          number_of_terms: nil,
                          induction_programme: 'fip')
      end

      it 'excludes the teacher' do
        expect(subject.former).not_to include(teacher)
      end
    end
  end
end
