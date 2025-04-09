RSpec.shared_examples "an email step" do |current_step:, previous_step:, next_step:|
  subject { described_class.new(wizard:) }

  let(:ect) { FactoryBot.create(:ect_at_school_period, :active, :provider_led) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "1234567",
                     trs_first_name: "John",
                     trs_last_name: "Wayne",
                     corrected_name: "Jim Wayne",
                     date_of_birth: "01/01/1990",
                     email: 'initial@email.com')
  end
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:, store:, ect_id: ect.id) }

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    let(:email) { 'provided@email.example' }

    context 'when the email is provided' do
      let(:params) { { email: } }

      it 'populate the instance from it' do
        expect(subject.email).to eq(email)
      end
    end

    context 'when no email is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.email).to eq('initial@email.com')
      end
    end
  end

  describe 'validations' do
    it { is_expected.to allow_value('valid@email.com').for(:email) }
    it { is_expected.not_to allow_value('invalid email').for(:email) }
  end

  describe '#next_step' do
    let(:step_params) do
      ActionController::Parameters.new("email_address" => { "email" => 'valid@email.com' })
    end

    let(:wizard) do
      FactoryBot.build(:register_mentor_wizard, current_step:, store:, step_params:, ect_id: ect.id)
    end

    it { expect(wizard.next_step).to eq(next_step) }
  end

  describe '#previous_step' do
    subject { FactoryBot.build(:register_mentor_wizard, current_step:, step_params:, ect_id: ect.id).current_step }

    let(:step_params) do
      ActionController::Parameters.new("email_address" => { "email" => 'valid@email.com' })
    end

    it { expect(subject.previous_step).to eq(previous_step) }
  end
end
