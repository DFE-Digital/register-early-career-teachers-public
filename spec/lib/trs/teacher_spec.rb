RSpec.describe TRS::Teacher do
  subject { described_class.new(data) }

  let(:data) do
    {
      'trn' => '1234567',
      'firstName' => 'John',
      'middleName' => 'A.',
      'lastName' => 'Doe',
      'dateOfBirth' => '1980-01-01',
      'nationalInsuranceNumber' => 'AB123456C',
      'emailAddress' => 'john.doe@example.com',
      'eyts' => { 'awarded' => '2024-09-18', 'certificateUrl' => 'eyts_certificate_url', 'statusDescription' => 'eyts_status' },
      'alerts' => [
        {
          'alertId' => '3fa85f64-5717-4562-b3fc-2c963f66afa6',
          'alertType' => {
            'alertTypeId' => '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            'alertCategory' => {
              'alertCategoryId' => '3fa85f64-5717-4562-b3fc-2c963f66afa6',
              'name' => 'Category Name'
            },
            'name' => 'Type Name'
          },
          'startDate' => '2024-09-18',
          'endDate' => '2024-09-18'
        }
      ],
      'induction' => {
        'startDate' => '2024-09-18',
        'endDate' => '2024-09-18',
        'status' => 'Exempt',
        'statusDescription' => 'Induction Status Description',
        'certificateUrl' => 'induction_certificate_url'
      },
      'pendingNameChange' => true,
      'pendingDateOfBirthChange' => true,
      'qts' => { 'awarded' => '2024-09-18', 'certificateUrl' => 'qts_certificate_url', 'statusDescription' => 'qts_status' },
      'initialTeacherTraining' => [
        {
          'qualification' => { 'name' => 'Qualification Name' },
          'ageRange' => { 'description' => 'Age Range Description' },
          'provider' => { 'name' => 'Provider Name', 'ukprn' => 'Provider UKPRN' },
          'subjects' => [{ 'code' => 'Subject Code', 'name' => 'Subject Name' }],
          'startDate' => '2024-09-18',
          'endDate' => '2024-09-18',
          'programmeType' => 'Apprenticeship',
          'programmeTypeDescription' => 'Programme Type Description',
          'result' => 'Pass'
        }
      ],
      'npqQualifications' => [
        {
          'type' => { 'code' => 'NPQEL', 'name' => 'NPQEL Name' },
          'awarded' => '2024-09-18',
          'certificateUrl' => 'npq_certificate_url'
        }
      ],
      'mandatoryQualifications' => [
        {
          'awarded' => '2024-09-18',
          'specialism' => 'Specialism'
        }
      ],
      'higherEducationQualifications' => [
        {
          'subjects' => [{ 'code' => 'HE Subject Code', 'name' => 'HE Subject Name' }],
          'name' => 'HE Qualification Name',
          'awarded' => '2024-09-18'
        }
      ],
      'previousNames' => [
        {
          'firstName' => 'Previous First Name',
          'middleName' => 'Previous Middle Name',
          'lastName' => 'Previous Last Name'
        }
      ],
      'allowIdSignInWithProhibitions' => true
    }
  end

  describe '#present' do
    it 'returns a hash with flattened attributes' do
      expected_hash = {
        trn: '1234567',
        date_of_birth: '1980-01-01',
        trs_first_name: 'John',
        trs_last_name: 'Doe',
        trs_email_address: 'john.doe@example.com',
        trs_alerts: data['alerts'],
        trs_induction_start_date: '2024-09-18',
        trs_induction_status: 'Exempt',
        trs_induction_status_description: 'Induction Status Description',
        trs_initial_teacher_training_end_date: "2024-09-18",
        trs_initial_teacher_training_provider_name: "Provider Name",
        trs_qts_awarded_on: '2024-09-18',
        trs_qts_status_description: 'qts_status',
        trs_national_insurance_number: "AB123456C",
      }

      expect(subject.present).to eq(expected_hash)
    end
  end

  describe "#check_eligibility!" do
    context "when the teacher has not been awarded QTS" do
      let(:data) { { 'qts' => { 'awarded' => nil } } }

      it "raises TRS::Errors::QTSNotAwarded" do
        expect { subject.check_eligibility! }.to raise_error(TRS::Errors::QTSNotAwarded)
      end
    end

    context "when the teacher is prohibited from teaching" do
      let(:data) do
        {
          'qts' => { 'awarded' => '2024-09-18' },
          'alerts' => [
            {
              'alertType' => { 'alertCategory' => { 'alertCategoryId' => 'b2b19019-b165-47a3-8745-3297ff152581' } },
            }
          ],
        }
      end

      it "raises TRS::Errors::ProhibitedFromTeaching" do
        expect { subject.check_eligibility! }.to raise_error(TRS::Errors::ProhibitedFromTeaching)
      end
    end

    context "when the teacher has completed induction" do
      let(:data) do
        {
          'qts' => { 'awarded' => '2024-09-18' },
          'induction' => { 'status' => 'Passed' },
          'alerts' => []
        }
      end

      it "raises TRS::Errors::InductionAlreadyCompleted" do
        expect { subject.check_eligibility! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher is eligible" do
      let(:data) do
        {
          'qts' => { 'awarded' => '2024-09-18' },
          'induction' => { 'status' => 'RequiredToComplete' },
          'alerts' => []
        }
      end

      it "returns true" do
        expect(subject.check_eligibility!).to be true
      end
    end
  end

  describe '#prohibited_from_teaching?' do
    context 'when teacher has a prohibition alert' do
      let(:data) do
        {
          'alerts' => [
            {
              'alertType' => { 'alertCategory' => { 'alertCategoryId' => 'b2b19019-b165-47a3-8745-3297ff152581' } },
            }
          ]
        }
      end

      it { is_expected.to be_prohibited_from_teaching }
    end

    context 'when teacher has no alerts' do
      let(:data) { { 'alerts' => [] } }

      it { is_expected.not_to be_prohibited_from_teaching }
    end

    context "when teacher has different type of alert" do
      let(:data) do
        {
          'alerts' => [
            {
              'alertType' => { 'alertCategory' => { 'alertCategoryId' => 'different_category' } },
            }
          ]
        }
      end

      it { is_expected.not_to be_prohibited_from_teaching }
    end
  end

  describe '#induction_completed?' do
    context 'when teacher has passed induction' do
      let(:data) { { 'induction' => { 'status' => 'Passed' } } }

      it { is_expected.to be_induction_completed }
    end

    context 'when teacher has failed induction' do
      let(:data) { { 'induction' => { 'status' => 'Failed' } } }

      it { is_expected.to be_induction_completed }
    end

    context 'when teacher is exempt from induction' do
      let(:data) { { 'induction' => { 'status' => 'Exempt' } } }

      it { is_expected.to be_induction_completed }
    end

    context 'when teacher has not completed induction' do
      let(:data) { { 'induction' => { 'status' => 'InProgress' } } }

      it { is_expected.not_to be_induction_completed }
    end

    context 'when teacher is required to complete induction' do
      let(:data) { { 'induction' => { 'status' => 'RequiredToComplete' } } }

      it { is_expected.not_to be_induction_completed }
    end
  end
end
