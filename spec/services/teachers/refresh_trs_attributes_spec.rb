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
        expect(teacher.trs_induction_status).to eql('Pass')
        expect(teacher.trs_qts_awarded_on).to eql(3.years.ago.to_date)
        expect(teacher.trs_qts_status_description).to eql('Passed')
        expect(teacher.trs_initial_teacher_training_provider_name).to eql('Example Provider Ltd.')
        expect(teacher.trs_initial_teacher_training_end_date).to eql(Date.new(2021, 4, 5))
        expect(teacher.trs_data_last_refreshed_at).to eql(Time.zone.now)
      end
    end

    it 'adds a teacher_name_updated_by_trs event' do
      expect(teacher.events).to be_empty

      Teachers::RefreshTRSAttributes.new(teacher).refresh!

      perform_enqueued_jobs

      expect(teacher.events.last.event_type).to eql('teacher_name_updated_by_trs')
    end
  end
end
