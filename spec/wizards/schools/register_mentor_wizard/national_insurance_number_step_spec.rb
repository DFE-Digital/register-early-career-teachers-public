describe Schools::RegisterMentorWizard::NationalInsuranceNumberStep, type: :model do
  subject { described_class.new }

  describe 'validations' do
    ['Ab123456A',
     'AB123456   A',
     'ab 12 34 56 A',
     'A B 1 2 3 4 5 6 a',].each do |dob|
      it { is_expected.to allow_value(dob).for(:national_insurance_number) }
    end

    %w[DA456A
       FA123456A
       IA123456A
       QA13456A
       UA123456A
       va1256A
       kn123456A
       TN123456A
       ZZ123456A].each do |dob|
      it { is_expected.not_to allow_value(dob).for(:national_insurance_number) }
    end
  end

  describe '#next_step' do
    let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :national_insurance_number, step_params:) }
    let(:step_params) do
      ActionController::Parameters.new(
        "national_insurance_number" => {
          "national_insurance_number" => 'AB123456A'
        }
      )
    end

    subject { wizard.current_step }

    context 'when the mentor is not found in TRS' do
      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(raise_not_found: true))
        subject.save!
      end

      it 'returns :not_found' do
        expect(subject.next_step).to eq(:not_found)
      end
    end

    context 'when the mentor is already active at the school' do
      let(:teacher) { FactoryBot.create(:teacher, trn: '1234568') }
      let(:active_mentor_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher:) }

      before do
        wizard.store.update!(trn: '1234568', school_urn: active_mentor_period.school.urn)
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
        subject.save!
      end

      it 'returns :already_active_at_school' do
        expect(subject.next_step).to eq(:already_active_at_school)
      end
    end

    context 'otherwise' do
      let(:school) { FactoryBot.create(:school) }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
        wizard.store.update!(school_urn: school.urn)
        subject.save!
      end

      it 'returns :review_mentor_details' do
        expect(subject.next_step).to eq(:review_mentor_details)
      end
    end
  end

  context '#save!' do
    context 'when the step is not valid' do
      let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :national_insurance_number) }
      subject { wizard.current_step }

      it 'does not update any data in the wizard mentor' do
        expect { subject.save! }.not_to change(subject.mentor, :national_insurance_number)
        expect { subject.save! }.not_to change(subject.mentor, :trs_first_name)
        expect { subject.save! }.not_to change(subject.mentor, :trs_last_name)
      end
    end

    context 'when the step is valid' do
      let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :national_insurance_number, step_params:) }
      let(:step_params) do
        ActionController::Parameters.new(
          "national_insurance_number" => {
            "national_insurance_number" => 'AB123456A'
          }
        )
      end

      subject { wizard.current_step }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
      end

      it 'updates the wizard mentor national insurance number and TRS data' do
        expect { subject.save! }
          .to change(subject.mentor, :national_insurance_number).from(nil).to('AB123456A')
          .and change(subject.mentor, :trs_first_name).from(nil).to('Kirk')
          .and change(subject.mentor, :trs_last_name).from(nil).to('Van Houten')
      end
    end
  end
end
