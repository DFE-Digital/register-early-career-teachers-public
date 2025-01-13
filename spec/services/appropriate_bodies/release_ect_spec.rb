describe AppropriateBodies::ReleaseECT do
  let(:induction_period) { FactoryBot.create(:induction_period, :active) }
  let(:appropriate_body) { induction_period.appropriate_body }
  let(:pending_induction_submission) do
    FactoryBot.create(
      :pending_induction_submission,
      :finishing,
      appropriate_body:,
      trn: induction_period.teacher.trn
    )
  end
  let(:author) do
    Sessions::Users::AppropriateBodyUser.new(
      name: 'A user',
      email: 'ab_user@something.org',
      dfe_sign_in_user_id: SecureRandom.uuid,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
    )
  end

  subject do
    AppropriateBodies::ReleaseECT.new(
      appropriate_body:,
      pending_induction_submission:,
      author:
    )
  end

  before { allow(Events::Record).to receive(:new).and_call_original }

  describe 'initialization' do
    it 'is initialized with an appropriate body and pending induction submission' do
      expect(subject).to be_a(AppropriateBodies::ReleaseECT)
    end

    it 'sets assigns the right teacher' do
      expect(subject.instance_variable_get(:@teacher)).to eql(induction_period.teacher)
    end
  end

  describe 'release!' do
    it 'closes the induction period setting the finished_on date and number_of_terms' do
      expect(induction_period.number_of_terms).to be_blank
      expect(induction_period.finished_on).to be_blank

      subject.release!
      induction_period.reload

      expect(induction_period.number_of_terms).to be_present
      expect(induction_period.finished_on).to be_present

      expect(induction_period.number_of_terms).to eql(pending_induction_submission.number_of_terms)
      expect(induction_period.finished_on).to eql(pending_induction_submission.finished_on)

      expect(Events::Record).to have_received(:new).with(
        hash_including(
          author:,
          event_type: :appropriate_body_releases_teacher,
          appropriate_body:,
          induction_period:,
          teacher: induction_period.teacher,
          heading: "#{Teachers::Name.new(induction_period.teacher).full_name} was released by #{appropriate_body.name}"
        )
      )
    end

    it 'destroys the pending_induction_submission' do
      subject.release!
      expect(PendingInductionSubmission.where(id: pending_induction_submission.id)).to be_empty
    end

    context "when an ECT has no ongoing induction periods" do
      it 'raises an error' do
        induction_period.destroy!

        expect { subject.release! }.to raise_error(AppropriateBodies::Errors::ECTHasNoOngoingInductionPeriods)
      end
    end
  end
end
