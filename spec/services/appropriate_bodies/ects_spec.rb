describe AppropriateBodies::ECTs do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  subject { AppropriateBodies::ECTs.new(appropriate_body) }

  describe "#current_or_completeed_while_at_appropriate_body" do
    it 'returns teachers whose latest induction period is with this AB' do
      # Earlier induction period with another AB
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body: other_appropriate_body,
                        started_on: 1.year.ago,
                        finished_on: 6.months.ago,
                        number_of_terms: 3,
                        induction_programme: 'fip')
      # Latest induction period with current AB
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: 6.months.ago,
                        finished_on: 1.month.ago,
                        outcome: 'pass',
                        number_of_terms: 3,
                        induction_programme: 'fip')

      expect(subject.current_or_completeed_while_at_appropriate_body).to include(teacher)
    end

    it 'does not return teachers whose latest induction period is with another AB' do
      # Earlier induction period with current AB
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: 1.year.ago,
                        finished_on: 6.months.ago,
                        number_of_terms: 3,
                        induction_programme: 'fip')
      # Latest induction period with another AB
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body: other_appropriate_body,
                        started_on: 6.months.ago,
                        finished_on: 1.month.ago,
                        outcome: 'pass', # pass or fail should be on last IP
                        number_of_terms: 3,
                        induction_programme: 'fip')

      expect(subject.current_or_completeed_while_at_appropriate_body).not_to include(teacher)
    end

    it 'returns teachers with ongoing induction periods' do
      # Earlier finished period with another AB
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body: other_appropriate_body,
                        started_on: 1.year.ago,
                        finished_on: 6.months.ago,
                        number_of_terms: 3,
                        induction_programme: 'fip')
      # Latest ongoing period with current AB
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: 6.months.ago,
                        finished_on: nil,
                        number_of_terms: nil,
                        induction_programme: 'fip')

      expect(subject.current_or_completeed_while_at_appropriate_body).to include(teacher)
    end

    it 'returns teachers with failed outcomes' do
      # Earlier period with pass outcome
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: 1.year.ago,
                        finished_on: 6.months.ago,
                        outcome: 'pass',
                        number_of_terms: 3,
                        induction_programme: 'fip')
      # Latest period with fail outcome
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: 6.months.ago,
                        finished_on: 1.month.ago,
                        outcome: 'fail',
                        number_of_terms: 3,
                        induction_programme: 'fip')

      expect(subject.current_or_completeed_while_at_appropriate_body).to include(teacher)
    end

    it 'does not return teachers with finished induction periods that have no outcome' do
      # Latest period with no outcome
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: 6.months.ago,
                        finished_on: 1.month.ago,
                        outcome: nil,
                        number_of_terms: 3,
                        induction_programme: 'fip')

      expect(subject.current_or_completeed_while_at_appropriate_body).not_to include(teacher)
    end
  end

  describe "#former" do
    it 'returns teachers with finished induction periods' do
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        finished_on: 1.month.ago,
                        number_of_terms: 3,
                        induction_programme: 'fip')

      expect(subject.former).to include(teacher)
    end

    it 'does not return teachers with ongoing induction periods' do
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        finished_on: nil,
                        number_of_terms: nil,
                        induction_programme: 'fip')

      expect(subject.former).not_to include(teacher)
    end
  end
end
