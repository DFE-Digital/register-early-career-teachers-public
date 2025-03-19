require "rails_helper"

RSpec.describe Admin::CreateInductionPeriod do
  let(:admin) { FactoryBot.create(:user, email: 'admin-user@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: admin.email) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:appropriate_body_id) { appropriate_body.id }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:teacher_id) { teacher.id }
  let(:started_on) { Date.new(2025, 1, 1) }
  let(:finished_on) { nil }
  let(:induction_programme) { 'fip' }
  let(:number_of_terms) { nil }

  let(:params) do
    { author:, appropriate_body_id:, teacher_id:, started_on:, finished_on:, induction_programme:, number_of_terms: }
  end

  subject { Admin::CreateInductionPeriod.new(author:, **params).create_induction_period! }

  describe '#create_induction_period!' do
    include ActiveJob::TestHelper

    before do
      allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
    end

    it 'returns a saved induction period record' do
      expect(subject).to be_a(InductionPeriod)
      expect(subject).to be_persisted
    end

    it 'has the right attributes' do
      aggregate_failures('assigning the right attributes') do
        expect(subject.appropriate_body).to eql(appropriate_body)
        expect(subject.teacher).to eql(teacher)
        expect(subject.started_on).to eql(started_on)
        expect(subject.induction_programme).to eql(induction_programme)
        expect(subject.number_of_terms).to be_nil
        expect(subject.finished_on).to be_nil
      end
    end

    it 'writes an event' do
      expect(Events::Record).to receive(:record_admin_creates_induction_period!).once.and_call_original

      induction_period = subject

      perform_enqueued_jobs

      event = Event.last

      aggregate_failures do
        expect(event.event_type).to eql('admin_creates_induction_period')
        expect(event.appropriate_body).to eql(appropriate_body)
        expect(event.teacher).to eql(teacher)
        expect(event.induction_period).to eql(induction_period)
      end
    end

    context 'when it begins earlier than any sibling induction periods' do
      it 'notifies TRS of the new induction start date'
    end

    context 'when finished' do
      let(:finished_on) { Date.new(2025, 2, 2) }
      let(:number_of_terms) { 1 }

      it 'returns a saved induction period record' do
        expect(subject).to be_persisted
      end

      it 'has the right attributes' do
        aggregate_failures('assigning the right attributes') do
          expect(subject.number_of_terms).to eq(number_of_terms)
          expect(subject.finished_on).to eql(finished_on)
        end
      end
    end

    context 'when invalid' do
      let(:finished_on) { started_on - 1.day }

      it 'returns an unsaved induction period record' do
        expect(subject).not_to be_persisted
      end

      it 'the induction period has errors' do
        expect(subject.errors).to have_key(:finished_on)
      end
    end
  end
end
