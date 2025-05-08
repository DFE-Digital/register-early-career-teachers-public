describe Teachers::RefreshTRSAttributes do
  include ActiveJob::TestHelper

  describe '#refresh!' do
    include_context 'fake trs api client that finds teacher that has passed their induction'

    let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Kermit", trs_last_name: "Van Bouten") }

    it 'updates the relevant TRS attributes' do
      freeze_time do
        Teachers::RefreshTRSAttributes.new(teacher).refresh!

        teacher.reload

        # these values are returned by the fake API client
        expect(teacher.trs_first_name).to eql('Kirk')
        expect(teacher.trs_last_name).to eql('Van Houten')
        expect(teacher.trs_induction_status).to eql('Passed')
        expect(teacher.trs_qts_awarded_on).to eql(3.years.ago.to_date)
        expect(teacher.trs_qts_status_description).to eql('Passed')
        expect(teacher.trs_initial_teacher_training_provider_name).to eql('Example Provider Ltd.')
        expect(teacher.trs_initial_teacher_training_end_date).to eql(Date.new(2021, 4, 5))
        expect(teacher.trs_data_last_refreshed_at).to eql(Time.zone.now)
      end
    end

    describe 'using Teachers::Manage' do
      let(:fake_manage) { double(Teachers::Manage, update_name!: true, update_trs_attributes!: true, update_trs_induction_status!: true) }

      before do
        allow(Teachers::Manage).to receive(:new).with(
          hash_including(teacher:, author: an_instance_of(Events::SystemAuthor), appropriate_body: nil)
        ).and_return(fake_manage)
      end

      it 'uses Teachers::Manage#update_name! to update the name' do
        Teachers::RefreshTRSAttributes.new(teacher).refresh!

        expect(fake_manage).to have_received(:update_name!).once.with(trs_first_name: 'Kirk', trs_last_name: 'Van Houten')
      end

      it 'uses Teachers::Manage#update_trs_induction_status! to update the induction status' do
        Teachers::RefreshTRSAttributes.new(teacher).refresh!

        expect(fake_manage).to have_received(:update_trs_induction_status!).once.with(trs_induction_status: 'Passed')
      end
    end

    it 'adds a teacher_name_updated_by_trs event' do
      expect(teacher.events).to be_empty

      Teachers::RefreshTRSAttributes.new(teacher).refresh!

      perform_enqueued_jobs

      expected_events = %w[teacher_name_updated_by_trs teacher_trs_induction_status_updated teacher_trs_attributes_updated]

      expect(teacher.events.last(expected_events.count).map(&:event_type)).to eql(expected_events)
    end

    context 'when the teacher has been deactivated in TRS' do
      include_context 'fake trs api client deactivated teacher'

      let(:fake_manage) do
        double(Teachers::Manage, mark_teacher_as_deactivated!: true)
      end

      before do
        allow(Teachers::Manage).to receive(:new).with(any_args).and_return(fake_manage)
      end

      it "marks the teacher as deactivated when the TRS reports the teacher as 'gone'" do
        Teachers::RefreshTRSAttributes.new(teacher).refresh!

        expect(fake_manage).to have_received(:mark_teacher_as_deactivated!).once.with(
          trs_data_last_refreshed_at: within(0.001.seconds).of(Time.zone.now)
        )
      end
    end
  end
end
