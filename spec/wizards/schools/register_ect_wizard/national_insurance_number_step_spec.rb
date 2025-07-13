describe Schools::RegisterECTWizard::NationalInsuranceNumberStep, type: :model do
  subject { described_class.new(wizard:) }

  let(:step_params) do
    ActionController::Parameters.new(
      "national_insurance_number" => {
        'national_insurance_number' => 'Ab123456A'
      }
    )
  end

  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "1234567",
                     trs_first_name: "John",
                     trs_last_name: "Wayne",
                     change_name: "yes",
                     corrected_name: "Jim Wayne",
                     date_of_birth: "01/01/1990",
                     national_insurance_number: "JL056123D")
  end
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :national_insurance_number, store:) }

  describe 'validations' do
    [
      "Ab123456A",
      "AB123456   A",
      "ab 12 34 56 A",
      "A B 1 2 3 4 5 6 a",
    ].each do |value|
      it { is_expected.to allow_value(value).for(:national_insurance_number) }
    end

    %w[DA123456A
       FA123456A
       IA123456A
       QA123456A
       UA123456A].each do |value|
      it { is_expected.not_to allow_value(value).for(:national_insurance_number) }
    end
  end

  describe '#next_step' do
    subject { wizard.current_step }

    let(:test_trs_client) { TRS::TestAPIClient.new }
    let(:fake_trs_teacher) do
      TRS::Teacher.new(
        'trn' => '1234568',
        'firstName' => 'Kirk',
        'lastName' => 'Van Houten',
        'dateOfBirth' => '1977-02-03',
        'induction' => {
          'status' => induction_status
        }
      )
    end
    let(:induction_status) {}
    let(:school) { FactoryBot.create(:school, :state_funded) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :national_insurance_number, step_params:, school:) }

    context 'when the ect is not found in TRS' do
      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(raise_not_found: true))
        subject.save!
      end

      it 'returns :not_found' do
        expect(subject.next_step).to eq(:not_found)
      end
    end

    context 'blocking registration' do
      let(:teacher) { FactoryBot.create(:teacher, trn: '1234568') }

      before do
        allow(test_trs_client).to receive(:find_teacher).and_return(fake_trs_teacher)
        allow(::TRS::APIClient).to receive(:new).and_return(test_trs_client)
        subject.save!
      end

      context 'when the teacher completed induction' do
        let(:induction_status) { 'Passed' }

        it 'returns :induction_completed' do
          expect(subject.next_step).to eq(:induction_completed)
        end
      end

      context 'when the teacher is exempt from induction' do
        let(:induction_status) { 'Exempt' }

        it 'returns :induction_exempt' do
          expect(subject.next_step).to eq(:induction_exempt)
        end
      end

      context 'when the teacher failed induction' do
        let(:induction_status) { 'Failed' }

        it 'returns :induction_failed' do
          expect(subject.next_step).to eq(:induction_failed)
        end
      end
    end

    context 'otherwise' do
      let(:school) { FactoryBot.create(:school) }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new)
        wizard.store.update!(school_urn: school.urn)
        subject.save!
      end

      it 'returns :review_ect_details' do
        expect(subject.next_step).to eq(:review_ect_details)
      end
    end
  end

  describe '#previous_step' do
    subject { wizard.current_step }

    let(:school) { FactoryBot.create(:school, :state_funded) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :national_insurance_number, step_params:, school:) }

    it 'returns :find_ect' do
      expect(subject.previous_step).to eq(:find_ect)
    end
  end

  context '#save!' do
    context 'when the step is not valid' do
      subject { wizard.current_step }

      let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :national_insurance_number) }

      it 'does not update any data in the wizard ect' do
        expect { subject.save! }.not_to change(subject.ect, :national_insurance_number)
        expect { subject.save! }.not_to change(subject.ect, :trs_date_of_birth)
        expect { subject.save! }.not_to change(subject.ect, :trs_national_insurance_number)
        expect { subject.save! }.not_to change(subject.ect, :trs_first_name)
        expect { subject.save! }.not_to change(subject.ect, :trs_last_name)
        expect { subject.save! }.not_to change(subject.ect, :trs_induction_status)
      end
    end

    context 'when the step is valid' do
      subject { wizard.current_step }

      let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :national_insurance_number, step_params:) }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new)
      end

      it 'updates the wizard ect and TRS data' do
        expect { subject.save! }
          .to change(subject.ect, :national_insurance_number).from(nil).to('Ab123456A')
                                                             .and change(subject.ect, :trs_date_of_birth).from(nil).to('1977-02-03')
                                                                                                         .and change(subject.ect, :trs_national_insurance_number).from(nil).to('Ab123456A')
                                                                                                                                                                 .and change(subject.ect, :trs_first_name).from(nil).to('Kirk')
                                                                                                                                                                                                          .and change(subject.ect, :trs_last_name).from(nil).to('Van Houten')
      end
    end
  end
end
