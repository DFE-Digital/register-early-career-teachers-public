RSpec.shared_examples "a review mentor details step" do |current_step:, next_step:|
  subject { described_class.new(wizard:) }

  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: '1234567',
                     trs_first_name: 'John',
                     trs_last_name: 'Wayne',
                     change_name: 'yes',
                     corrected_name: 'Jim Wayne',
                     date_of_birth: '01/01/1990',
                     email: 'initial@email.com')
  end
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:, store:) }

  describe '#initialisation' do
    subject { described_class.new(wizard:, **params) }

    let(:corrected_name) { 'Right Name' }

    context 'when the corrected name or change name are provided' do
      let(:params) { { corrected_name:, change_name: 'yes' } }

      it 'populate the instance from it' do
        expect(subject.corrected_name).to eq(corrected_name)
        expect(subject.change_name).to eq('yes')
      end
    end

    context 'when no corrected_name is provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.corrected_name).to eq('Jim Wayne')
        expect(subject.change_name).to eq('yes')
      end
    end
  end

  describe 'validations' do
    it do
      is_expected.to validate_inclusion_of(:change_name)
                       .in_array(%w[yes no])
                       .with_message("Select 'Yes' or 'No' to confirm whether the details are correct")
    end

    context "when change_name is 'no'" do
      subject { described_class.new(change_name: 'no') }

      it { is_expected.to allow_value('Rick Collins').for(:corrected_name) }

      ['a' * 71, ' ', nil].each do |value|
        it { is_expected.not_to allow_value(value).for(:corrected_name) }
      end
    end

    context "when change_name is not 'no'" do
      subject { described_class.new(change_name: 'yes') }

      ['Rick Collins', 'a' * 71, ' ', nil].each do |value|
        it { is_expected.to allow_value(value).for(:corrected_name) }
      end
    end
  end

  describe '#next_step' do
    let(:step_params) do
      ActionController::Parameters.new("review_mentor_details" => { "change_name" => 'yes',
                                                                    "corrected_name" => 'Another Name' })
    end

    let(:wizard) do
      FactoryBot.build(:register_mentor_wizard, current_step:, step_params:)
    end

    it { expect(subject.next_step).to eq(next_step) }
  end

  context '#save!' do
    context 'when the step is not valid' do
      subject { wizard.current_step }

      let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:) }

      it 'does not update any data in the wizard mentor' do
        expect { subject.save! }.not_to change(subject.mentor, :corrected_name)
      end
    end

    context 'when the step is valid' do
      subject { wizard.current_step }

      let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:, step_params:) }
      let(:step_params) do
        ActionController::Parameters.new(
          current_step.to_s => {
            "change_name" => 'no',
            "corrected_name" => "Paul Saints",
          }
        )
      end

      it "'updates the wizard's mentor corrected name'" do
        expect { subject.save! }
          .to change(subject.mentor, :corrected_name)
                .from(nil).to('Paul Saints')
                .and change(subject.mentor, :change_name)
                       .from(nil).to('no')
      end
    end
  end
end
