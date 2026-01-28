RSpec.describe TRS::Teacher do
  subject(:service) { described_class.new(data) }

  let(:data) do
    {
      "trn" => "1234567",
      "firstName" => "John",
      "middleName" => "A.",
      "lastName" => "Doe",
      "dateOfBirth" => "1980-01-01",
      "nationalInsuranceNumber" => "AB123456C",
      "emailAddress" => "john.doe@example.com",
      "eyts" => {
        "holdsFrom" => "2024-09-18",
        "routes" => [],
      },
      "alerts" => [
        {
          "alertId" => "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "alertType" => {
            "alertTypeId" => "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            "alertCategory" => {
              "alertCategoryId" => "3fa85f64-5717-4562-b3fc-2c963f66afa6",
              "name" => "Category Name"
            },
            "name" => "Type Name"
          },
          "startDate" => "2024-09-18",
          "endDate" => "2024-09-18"
        }
      ],
      "induction" => {
        "startDate" => "2024-09-18",
        "completedDate" => "2024-09-18",
        "status" => "InProgress",
        "exemptionReasons" => [
          {
            "inductionExemptionReasonId" => "a112e691-1694-46a7-8f33-5ec5b845c181",
            "name" => "They have or are eligible for full registration in Scotland"
          }
        ]
      },
      "pendingNameChange" => true,
      "pendingDateOfBirthChange" => true,
      "qts" => {
        "holdsFrom" => "2024-09-18",
        "routes" => [
          {
            "routeToProfessionalStatusType" => {
              "routeToProfessionalStatusTypeId" => "32017d68-9da4-43b2-ae91-4f24c68f6f78",
              "name" => "HEI - Historic",
              "professionalStatusType" => "QualifiedTeacherStatus"
            }
          }
        ]
      },
      "routesToProfessionalStatuses" => [
        {
          "routeToProfessionalStatusId" => "5598605e-d4a3-4846-96c9-df480ee57e38",
          "routeToProfessionalStatusType" => {
            "routeToProfessionalStatusTypeId" => "52835b1f-1f2e-4665-abc6-7fb1ef0a80bb",
            "name" => "Scottish Recognition",
            "professionalStatusType" => "QualifiedTeacherStatus"
          },
          "status" => "Holds",
          "holdsFrom" => "2024-09-19",
          "trainingStartDate" => "2024-09-18",
          "trainingEndDate" => "2024-09-18",
          "trainingSubjects" => [
            {
              "reference" => "X9005",
              "name" => "Primary Curriculum"
            }
          ],
          "trainingAgeSpecialism" => {
            "type" => "Range",
            "from" => 3,
            "to" => 11
          },
          "trainingCountry" => {
            "reference" => "GB-SCT",
            "name" => "Scotland"
          },
          "trainingProvider" => {
            "ukprn" => nil,
            "name" => "Provider Name"
          },
          "degreeType" => nil,
          "inductionExemption" => {
            "isExempt" => true,
            "exemptionReasons" => [
              {
                "inductionExemptionReasonId" => "a112e691-1694-46a7-8f33-5ec5b845c181",
                "name" => "They have or are eligible for full registration in Scotland"
              }
            ]
          }
        }
      ],
      "npqQualifications" => [
        {
          "type" => { "code" => "NPQEL", "name" => "NPQEL Name" },
          "awarded" => "2024-09-18",
          "certificateUrl" => "npq_certificate_url"
        }
      ],
      "mandatoryQualifications" => [
        {
          "awarded" => "2024-09-18",
          "specialism" => "Specialism"
        }
      ],
      "higherEducationQualifications" => [
        {
          "subjects" => [{ "code" => "HE Subject Code", "name" => "HE Subject Name" }],
          "name" => "HE Qualification Name",
          "awarded" => "2024-09-18"
        }
      ],
      "previousNames" => [
        {
          "firstName" => "Previous First Name",
          "middleName" => "Previous Middle Name",
          "lastName" => "Previous Last Name"
        }
      ],
      "allowIdSignInWithProhibitions" => true
    }
  end

  describe "#to_h" do
    it "returns a hash of attributes" do
      expect(service.to_h).to eq({
        trs_date_of_birth: "1980-01-01",
        trs_first_name: "John",
        trs_last_name: "Doe",
        trs_email_address: "john.doe@example.com",
        trs_alerts: %w[3fa85f64-5717-4562-b3fc-2c963f66afa6],
        trs_induction_start_date: "2024-09-18",
        trs_induction_status: "InProgress",
        trs_induction_completed_date: "2024-09-18",
        trs_initial_teacher_training_end_date: "2024-09-18",
        trs_initial_teacher_training_provider_name: "Provider Name",
        trs_qts_awarded_on: "2024-09-18",
        trs_qts_status_description: "QualifiedTeacherStatus",
        trs_prohibited_from_teaching: false,
      })
    end
  end

  describe "#check_eligibility!" do
    context "when the teacher is eligible" do
      it do
        expect { service.check_eligibility! }.not_to raise_error
      end
    end

    context "when the teacher is exempt" do
      let(:data) { { "induction" => { "status" => "Exempt" } } }

      it do
        expect { service.check_eligibility! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher has passed their induction" do
      let(:data) { { "induction" => { "status" => "Passed" } } }

      it do
        expect { service.check_eligibility! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher has failed their induction" do
      let(:data) { { "induction" => { "status" => "Failed" } } }

      it do
        expect { service.check_eligibility! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher has failed their induction (in Wales)" do
      let(:data) { { "induction" => { "status" => "FailedInWales" } } }

      it do
        expect { service.check_eligibility! }.to raise_error(TRS::Errors::InductionAlreadyCompleted)
      end
    end

    context "when the teacher has not been awarded QTS" do
      let(:data) { { "qts" => { "holdsFrom" => nil } } }

      it do
        expect { service.check_eligibility! }.to raise_error(TRS::Errors::QTSNotAwarded)
      end
    end

    context "when the teacher is prohibited from teaching" do
      let(:data) do
        {
          "qts" => { "holdsFrom" => "2024-09-18" },
          "alerts" => [
            {
              "alertType" => { "alertCategory" => { "alertCategoryId" => "b2b19019-b165-47a3-8745-3297ff152581" } },
            }
          ],
        }
      end

      it do
        expect { service.check_eligibility! }.to raise_error(TRS::Errors::ProhibitedFromTeaching)
      end
    end
  end

  describe "#prohibited_from_teaching?" do
    context "when teacher has a prohibition alert" do
      let(:data) do
        {
          "alerts" => [
            {
              "alertType" => { "alertCategory" => { "alertCategoryId" => "b2b19019-b165-47a3-8745-3297ff152581" } },
            }
          ]
        }
      end

      it { is_expected.to be_prohibited_from_teaching }
    end

    context "when teacher has no alerts" do
      let(:data) { { "alerts" => [] } }

      it { is_expected.not_to be_prohibited_from_teaching }
    end

    context "when teacher has different type of alert" do
      let(:data) do
        {
          "alerts" => [
            {
              "alertType" => { "alertCategory" => { "alertCategoryId" => "different_category" } },
            }
          ]
        }
      end

      it { is_expected.not_to be_prohibited_from_teaching }
    end
  end
end
