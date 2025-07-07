RSpec.shared_examples "a can't use email step" do |current_step:, previous_step:, next_step:|
  subject { described_class.new(wizard:) }

  let(:store) do
    build(:session_repository,
          trn: '1234567',
          trs_first_name: 'John',
          trs_last_name: 'Wayne',
          change_name: 'no',
          date_of_birth: '01/01/1990',
          email: 'initial@email.com')
  end
  let(:wizard) { build(:register_mentor_wizard, current_step:, store:) }

  describe '#next_step' do
    it { expect(wizard.next_step).to eq(next_step) }
  end

  describe '#previous_step' do
    subject { wizard.current_step }

    it { expect(subject.previous_step).to eq(previous_step) }
  end
end
