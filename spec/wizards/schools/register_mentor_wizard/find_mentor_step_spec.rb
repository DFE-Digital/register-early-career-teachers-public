describe Schools::RegisterMentorWizard::FindMentorStep, type: :model do
  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "1234567",
                     trs_first_name: "John",
                     trs_last_name: "Wayne",
                     corrected_name: "Jim Wayne",
                     date_of_birth: "01/01/1990")
  end
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :find_mentor, store:) }
  subject { described_class.new(wizard:) }

  describe '#initialize' do
    let(:trn) { '3333333' }
    subject(:instance) { described_class.new(wizard:, **params) }

    context 'when either trn or date_of_birth are provided' do
      let(:params) { { trn: } }

      it 'populate the instance from it' do
        expect(instance.trn).to eq(trn)
      end
    end

    context 'when no trn or date_of_birth are provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(instance.trn).to eq('1234567')
        expect(instance.date_of_birth).to eq({ 1 => 1990, 2 => 1, 3 => 1 })
      end
    end
  end

  describe 'validations' do
    ['12345', 'RP99/12345', 'RP / 1234567', '  R P 99 / 1234', 'ZZ-123445 '].each do |trn|
      it { is_expected.to allow_value(trn).for(:trn) }
    end

    ['1234', 'RP99/123457', 'No-numbers', '', nil].each do |trn|
      it { is_expected.not_to allow_value(trn).for(:trn) }
    end

    [{ 1 => '1990', 2 => '02', 3 => '15' }].each do |dob|
      it { is_expected.to allow_value(dob).for(:date_of_birth) }
    end

    [
      { 1 => 'invalid', 2 => '02', 3 => '30' },
      { 1 => '3000', 2 => '02', 3 => '15' },
      { 1 => (Date.current.year + 1).to_s, 2 => '02', 3 => '15' },
      nil,
      {}
    ].each do |dob|
      it { is_expected.not_to allow_value(dob).for(:date_of_birth) }
    end
  end

  describe '#next_step' do
    let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
    let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :find_mentor, step_params:, ect_id: ect.id) }
    let(:step_params) do
      ActionController::Parameters.new(
        "find_mentor" => {
          "trn" => '1234568',
          "date_of_birth(3i)" => "03",
          "date_of_birth(2i)" => "02",
          "date_of_birth(1i)" => "1977"
        }
      )
    end

    subject { wizard.current_step }

    context 'when the mentor is not found in TRS' do
      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(raise_not_found: true))
        subject.save!
      end

      it 'returns :trn_not_found' do
        expect(subject.next_step).to eq(:trn_not_found)
      end
    end

    context 'when the mentor trn matches that of the ECT' do
      let(:teacher) { FactoryBot.create(:teacher, trn: '1234568') }
      let(:ect) { FactoryBot.create(:ect_at_school_period, :active, teacher:) }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
        subject.save!
      end

      it 'returns :cannot_mentor_themself' do
        expect(subject.next_step).to eq(:cannot_mentor_themself)
      end
    end

    context 'when the date of birth does not match that on TRS' do
      let(:step_params) do
        ActionController::Parameters.new(
          "find_mentor" => {
            "trn" => '1234568',
            "date_of_birth(3i)" => "13",
            "date_of_birth(2i)" => "12",
            "date_of_birth(1i)" => "1971"
          }
        )
      end

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
        subject.save!
      end

      it 'returns :national_insurance_number' do
        expect(subject.next_step).to eq(:national_insurance_number)
      end
    end

    context 'when the mentor is already active at the school' do
      let(:teacher) { FactoryBot.create(:teacher, trn: '1234568') }
      let(:active_mentor_period) { FactoryBot.create(:mentor_at_school_period, :active, teacher:) }

      before do
        wizard.store.update!(school_urn: active_mentor_period.school.urn)
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
        subject.save!
      end

      it 'returns :already_active_at_school' do
        expect(subject.next_step).to eq(:already_active_at_school)
      end
    end

    context 'when the mentor is prohibited from teaching' do
      let(:teacher) { create(:teacher, trn: '1234568') }
      before do
        fake_client = TRS::FakeAPIClient.new

        allow(fake_client).to receive(:find_teacher).and_return(
          TRS::Teacher.new(
            'trn' => '1234568',
            'firstName' => 'Jane',
            'lastName' => 'Smith',
            'dateOfBirth' => '1977-02-03',
            'alerts' => [
              {
                'alertType' => {
                  'alertCategory' => {
                    'alertCategoryId' => TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID
                  }
                }
              }
            ]
          )
        )
        allow(::TRS::APIClient).to receive(:new).and_return(fake_client)
        subject.save!
      end

      it 'returns :cannot_register_mentor' do
        expect(subject.next_step).to eq(:cannot_register_mentor)
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
      let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :find_mentor) }
      subject { wizard.current_step }

      it 'does not update any data in the wizard mentor' do
        expect { subject.save! }.not_to change(subject.mentor, :trn)
        expect { subject.save! }.not_to change(subject.mentor, :date_of_birth)
        expect { subject.save! }.not_to change(subject.mentor, :trs_date_of_birth)
        expect { subject.save! }.not_to change(subject.mentor, :trs_first_name)
        expect { subject.save! }.not_to change(subject.mentor, :trs_last_name)
      end
    end

    context 'when the step is valid' do
      let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :find_mentor, step_params:) }
      let(:step_params) do
        ActionController::Parameters.new(
          "find_mentor" => {
            "trn" => '1234568',
            "date_of_birth(3i)" => "03",
            "date_of_birth(2i)" => "02",
            "date_of_birth(1i)" => "1977"
          }
        )
      end

      subject { wizard.current_step }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
      end

      it 'updates the wizard mentor trn and TRS data' do
        expect { subject.save! }
          .to change(subject.mentor, :trn).from(nil).to('1234568')
          .and change(subject.mentor, :date_of_birth).from(nil).to('3-2-1977')
          .and change(subject.mentor, :trs_date_of_birth).from(nil).to('1977-02-03')
          .and change(subject.mentor, :trs_first_name).from(nil).to('Kirk')
          .and change(subject.mentor, :trs_last_name).from(nil).to('Van Houten')
      end
    end
  end
end
