describe TRS::TestAPIClient do
  describe 'initializing' do
    it 'fails when used in production' do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { TRS::TestAPIClient.new }.to raise_error(TRS::TestAPIClient::TestAPIClientUsedInProduction)
    end
  end

  describe '#find_teacher' do
    subject(:client) { TRS::TestAPIClient.new(**kwargs) }

    let(:trs_teacher) { client.find_teacher(trn: '1234567') }

    context 'when initialized with raise_not_found' do
      let(:kwargs) { { raise_not_found: true } }

      it 'raises a TRS::Errors::TeacherNotFound error' do
        expect { trs_teacher }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end

    context 'when initialized with raise_deactivated' do
      let(:kwargs) { { raise_deactivated: true } }

      it 'raises a TRS::Errors::TeacherDeactivated error' do
        expect { trs_teacher }.to raise_error(TRS::Errors::TeacherDeactivated)
      end
    end

    context 'when initialized with has_alerts_but_not_prohibited' do
      let(:kwargs) { { has_alerts_but_not_prohibited: true } }

      it 'the teacher has alerts' do
        expect(trs_teacher).to have_alerts
      end

      it 'the teacher is not prohibited_from_teaching' do
        expect(trs_teacher).not_to be_prohibited_from_teaching
      end
    end

    context 'when initialized with prohibited_from_teaching' do
      let(:kwargs) { { is_prohibited_from_teaching: true } }

      it 'the teacher is prohibited from teaching' do
        expect(trs_teacher).to be_prohibited_from_teaching
      end
    end

    describe 'induction_statuses' do
      subject { trs_teacher.trs_induction_status }

      context 'when initialized induction_status: InProgress' do
        let(:kwargs) { { induction_status: 'InProgress' } }

        it { is_expected.to eql('InProgress') }
      end

      context 'when initialized induction_status: Passed' do
        let(:kwargs) { { induction_status: 'Passed' } }

        it { is_expected.to eql('Passed') }
      end

      context 'when initialized induction_status: Failed' do
        let(:kwargs) { { induction_status: 'Failed' } }

        it { is_expected.to eql('Failed') }
      end
    end

    describe 'QTS data' do
      context 'when initialized with has_qts: false' do
        let(:kwargs) { { has_qts: false } }

        it 'the teacher has no QTS awarded on date' do
          expect(trs_teacher.trs_qts_awarded_on).to be_nil
        end
      end

      context 'when initialized with has_qts: true' do
        let(:kwargs) { { has_qts: true } }

        it 'the teacher has a QTS awarded on date of 3 years ago' do
          expect(trs_teacher.trs_qts_awarded_on).to eql(3.years.ago.to_date)
        end
      end
    end

    describe 'ITT data' do
      context 'when initialized with has_itt: false' do
        let(:kwargs) { { has_itt: false } }

        it 'the teacher has no ITT training provider' do
          expect(trs_teacher.trs_initial_teacher_training_provider_name).to be_nil
        end
      end

      context 'when initialized with has_itt: true' do
        let(:kwargs) { { has_itt: true } }

        it 'the teacher has no ITT training provider' do
          expect(trs_teacher.trs_initial_teacher_training_provider_name).to eql('Example Provider Ltd.')
        end
      end
    end
  end
end
