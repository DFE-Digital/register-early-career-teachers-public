describe TRS::FakeAPIClient do
  describe 'initializing' do
    it 'fails when used in production' do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { TRS::FakeAPIClient.new }.to raise_error(TRS::FakeAPIClient::FakeAPIClientUsedInProduction)
    end
  end

  describe '#find_teacher' do
    subject { TRS::FakeAPIClient.new }

    context 'without a special TRN' do
      let(:trn) { 1_234_567 }

      it 'returns a teacher with a qts_awarded_on date' do
        expect(subject.find_teacher(trn:).qts_awarded_on).not_to be_nil
      end

      it 'returns a teacher who is not prohibited from teaching' do
        expect(subject.find_teacher(trn:)).not_to be_prohibited_from_teaching
      end
    end

    context 'with TRN is 7_000_001' do
      let(:trn) { 7_000_001 }

      it 'returns a teacher who is not QTS awarded' do
        expect(subject.find_teacher(trn:)).not_to be_qts_awarded
      end

      it 'returns a teacher without a qts_awarded_on date' do
        expect(subject.find_teacher(trn:).qts_awarded_on).to be_nil
      end
    end

    context 'when TRN is 7_000_002' do
      let(:trn) { 7_000_002 }

      it 'raises a TRS::Errors::TeacherNotFound error' do
        expect { subject.find_teacher(trn:) }.to raise_error(TRS::Errors::TeacherNotFound)
      end
    end

    context 'when TRN is 7_000_003' do
      let(:trn) { 7_000_003 }

      it 'returns a teacher with a prhohibited from teaching alert' do
        expect(subject.find_teacher(trn:)).to be_prohibited_from_teaching
      end
    end

    context 'when TRN is 7_000_004' do
      let(:trn) { 7_000_004 }

      it 'raises a TRS::Errors::TeacherNotFound error' do
        expect { subject.find_teacher(trn:) }.to raise_error(TRS::Errors::TeacherDeactivated)
      end
    end

    context 'when TRN is 7_000_005' do
      let(:trn) { 7_000_005 }

      it 'returns a teacher who has alerts' do
        expect(subject.find_teacher(trn:)).to have_alerts
      end

      it 'returns a teacher is not prohibited from teaching' do
        expect(subject.find_teacher(trn:)).not_to be_prohibited_from_teaching
      end
    end

    context "when TRN is 7_000_006" do
      let(:trn) { 7_000_006 }

      it 'returns a teacher (this teacher should be seeded with early_roll_out_mentor_attrs, see db/seeds/teachers.rb)' do
        expect(subject.find_teacher(trn:)).to be_present
      end
    end

    context 'when the teacher already exists in the database' do
      let(:trn) { 1_112_222 }

      before { FactoryBot.create(:teacher, trn:, trs_first_name: 'Christopher', trs_last_name: 'Eccleston') }

      it 'returns the TRS teacher with name of the existing teacher' do
        trs_teacher = subject.find_teacher(trn:)

        expect(trs_teacher.first_name).to eql('Christopher')
        expect(trs_teacher.last_name).to eql('Eccleston')
      end
    end
  end

  describe 'Redis data storing functionality', :redis do
    subject { TRS::FakeAPIClient.new }

    let(:teacher) { FactoryBot.build(:teacher) }
    let(:trn) { teacher.trn }
    let(:key) { trn + ':induction' }
    let(:start_date) { 3.months.ago.to_date }
    let(:redis_client) { Redis.new }

    before { redis_client.del(key) }

    describe '#begin_induction!' do
      before { subject.begin_induction!(trn: teacher.trn, start_date:) }

      it 'writes the in progress status to Redis' do
        expect(redis_client.hgetall(key)).to match(
          include(
            'status' => 'InProgress',
            'startDate' => start_date.to_s
          )
        )
      end

      it 'retrieves the teacher record with the updated info' do
        trs_teacher = subject.find_teacher(trn:)

        expect(trs_teacher.induction_status).to eql('InProgress')
      end
    end

    describe '#pass_induction!' do
      let(:completed_date) { 1.day.ago.to_date }

      before { subject.pass_induction!(trn: teacher.trn, start_date:, completed_date:) }

      it 'writes the passed status to Redis' do
        expect(redis_client.hgetall(key)).to match(
          include(
            'status' => 'Passed',
            'startDate' => start_date.to_s,
            'completedDate' => completed_date.to_s
          )
        )
      end

      it 'retrieves the teacher record with the updated info' do
        trs_teacher = subject.find_teacher(trn:)

        expect(trs_teacher.induction_status).to eql('Passed')
      end
    end

    describe '#fail_induction!' do
      let(:completed_date) { 1.day.ago.to_date }

      before { subject.fail_induction!(trn: teacher.trn, start_date:, completed_date:) }

      it 'writes the failed status to Redis' do
        expect(redis_client.hgetall(key)).to match(
          include(
            'status' => 'Failed',
            'startDate' => start_date.to_s,
            'completedDate' => completed_date.to_s
          )
        )
      end

      it 'retrieves the teacher record with the updated info' do
        trs_teacher = subject.find_teacher(trn:)

        expect(trs_teacher.induction_status).to eql('Failed')
      end
    end

    describe '#reset_teacher_induction' do
      let(:completed_date) { 1.day.ago.to_date }

      before { subject.reset_teacher_induction(trn: teacher.trn) }

      it 'clears the start date and completed date in Redis, and sets status back to required to complete' do
        expect(redis_client.hgetall(key)).to match(
          include(
            'status' => 'RequiredToComplete',
            'startDate' => '',
            'completedDate' => ''
          )
        )
      end

      it 'retrieves the teacher record with the updated info' do
        trs_teacher = subject.find_teacher(trn:)

        expect(trs_teacher.induction_status).to eql('RequiredToComplete')
      end
    end
  end
end
