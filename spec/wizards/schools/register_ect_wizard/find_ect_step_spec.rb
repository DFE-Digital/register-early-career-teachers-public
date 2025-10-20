describe Schools::RegisterECTWizard::FindECTStep, type: :model do
  subject { described_class.new(wizard:) }

  let(:store) do
    FactoryBot.build(:session_repository,
      trn: "1234567",
      trs_first_name: "John",
      trs_last_name: "Wayne",
      change_name: "yes",
      corrected_name: "Jim Wayne",
      date_of_birth: "01/01/1990")
  end
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :find_ect, store:) }

  describe "validations" do
    ["12345", "RP99/12345", "RP / 1234567", "  R P 99 / 1234", "ZZ-123445 "].each do |trn|
      it { is_expected.to allow_value(trn).for(:trn) }
    end

    ["1234", "RP99/123457", "No-numbers", "", nil].each do |trn|
      it { is_expected.not_to allow_value(trn).for(:trn) }
    end

    [{1 => "1990", 2 => "02", 3 => "15"}].each do |dob|
      it { is_expected.to allow_value(dob).for(:date_of_birth) }
    end

    [
      {1 => "invalid", 2 => "02", 3 => "30"},
      {1 => "3000", 2 => "02", 3 => "15"},
      {1 => (Date.current.year + 1).to_s, 2 => "02", 3 => "15"},
      nil,
      {}
    ].each do |dob|
      it { is_expected.not_to allow_value(dob).for(:date_of_birth) }
    end
  end

  describe "#next_step" do
    subject { wizard.current_step }

    let(:school) { FactoryBot.create(:school, :state_funded) }
    let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :find_ect, step_params:, school:) }
    let(:step_params) do
      ActionController::Parameters.new(
        "find_ect" => {
          "trn" => "1234568",
          "date_of_birth(3i)" => "03",
          "date_of_birth(2i)" => "02",
          "date_of_birth(1i)" => "1977"
        }
      )
    end

    context "when the ect is not found in TRS" do
      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new(raise_not_found: true))
        subject.save!
      end

      it "returns :trn_not_found" do
        expect(subject.next_step).to eq(:trn_not_found)
      end
    end

    context "when the date of birth does not match that on TRS" do
      let(:step_params) do
        ActionController::Parameters.new(
          "find_ect" => {
            "trn" => "1234568",
            "date_of_birth(3i)" => "13",
            "date_of_birth(2i)" => "12",
            "date_of_birth(1i)" => "1971"
          }
        )
      end

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new)
        subject.save!
      end

      it "returns :national_insurance_number" do
        expect(subject.next_step).to eq(:national_insurance_number)
      end
    end

    context "when the ect is already active at the school" do
      let(:teacher) { FactoryBot.create(:teacher, trn: "1234568") }
      let(:ongoing_ect_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, :ongoing, teacher:, school:) }

      before do
        wizard.store.update!(school_urn: ongoing_ect_period.school.urn)
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new)
        subject.save!
      end

      it "returns :already_active_at_school" do
        expect(subject.next_step).to eq(:already_active_at_school)
      end
    end

    context "when the teacher completed induction" do
      let(:teacher) { FactoryBot.create(:teacher, trn: "1234568") }

      before do
        test_client = TRS::TestAPIClient.new

        allow(test_client).to receive(:find_teacher).and_return(
          TRS::Teacher.new(
            "trn" => "1234568",
            "firstName" => "Kirk",
            "lastName" => "Van Houten",
            "dateOfBirth" => "1977-02-03",
            "induction" => {
              "status" => "Passed"
            }
          )
        )
        allow(::TRS::APIClient).to receive(:new).and_return(test_client)
        subject.save!
      end

      it "returns :induction_completed" do
        expect(subject.next_step).to eq(:induction_completed)
      end
    end

    context "when the teacher is exempt from induction" do
      let(:teacher) { FactoryBot.create(:teacher, trn: "1234568") }

      before do
        test_client = TRS::TestAPIClient.new

        allow(test_client).to receive(:find_teacher).and_return(
          TRS::Teacher.new(
            "trn" => "1234568",
            "firstName" => "Kirk",
            "lastName" => "Van Houten",
            "dateOfBirth" => "1977-02-03",
            "induction" => {
              "status" => "Exempt"
            }
          )
        )
        allow(::TRS::APIClient).to receive(:new).and_return(test_client)
        subject.save!
      end

      it "returns :induction_exempt" do
        expect(subject.next_step).to eq(:induction_exempt)
      end
    end

    context "when the teacher failed induction" do
      let(:teacher) { FactoryBot.create(:teacher, trn: "1234568") }

      before do
        test_client = TRS::TestAPIClient.new

        allow(test_client).to receive(:find_teacher).and_return(
          TRS::Teacher.new(
            "trn" => "1234568",
            "firstName" => "Kirk",
            "lastName" => "Van Houten",
            "dateOfBirth" => "1977-02-03",
            "induction" => {
              "status" => "Failed"
            }
          )
        )
        allow(::TRS::APIClient).to receive(:new).and_return(test_client)
        subject.save!
      end

      it "returns :induction_failed" do
        expect(subject.next_step).to eq(:induction_failed)
      end
    end

    context "when the teacher is prohibited from teaching" do
      let(:teacher) { FactoryBot.create(:teacher, trn: "1234568") }

      before do
        test_client = TRS::TestAPIClient.new

        allow(test_client).to receive(:find_teacher).and_return(
          TRS::Teacher.new(
            "trn" => "1234568",
            "firstName" => "Kirk",
            "lastName" => "Van Houten",
            "dateOfBirth" => "1977-02-03",
            "alerts" => [
              {
                "alertType" => {
                  "alertCategory" => {
                    "alertCategoryId" => TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID
                  }
                }
              }
            ]
          )
        )
        allow(::TRS::APIClient).to receive(:new).and_return(test_client)
        subject.save!
      end

      it "returns :cannot_register_ect" do
        expect(subject.next_step).to eq(:cannot_register_ect)
      end
    end

    context "otherwise" do
      let(:school) { FactoryBot.create(:school) }

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new)
        wizard.store.update!(school_urn: school.urn)
        subject.save!
      end

      it "returns :review_ect_details" do
        expect(subject.next_step).to eq(:review_ect_details)
      end
    end
  end

  describe "#save!" do
    context "when the step is not valid" do
      subject { wizard.current_step }

      let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :find_ect) }

      it "does not update any data in the wizard ect" do
        expect { subject.save! }.not_to change(subject.ect, :trn)
        expect { subject.save! }.not_to change(subject.ect, :date_of_birth)
        expect { subject.save! }.not_to change(subject.ect, :trs_date_of_birth)
        expect { subject.save! }.not_to change(subject.ect, :trs_first_name)
        expect { subject.save! }.not_to change(subject.ect, :trs_last_name)
      end
    end

    context "when the step is valid" do
      subject { wizard.current_step }

      let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :find_ect, step_params:) }
      let(:step_params) do
        ActionController::Parameters.new(
          "find_ect" => {
            "trn" => "1234568",
            "date_of_birth(3i)" => "03",
            "date_of_birth(2i)" => "02",
            "date_of_birth(1i)" => "1977"
          }
        )
      end

      before do
        allow(::TRS::APIClient).to receive(:new).and_return(TRS::TestAPIClient.new)
      end

      it "updates the wizard ect trn and TRS data" do
        expect { subject.save! }
          .to change(subject.ect, :trn).from(nil).to("1234568")
          .and change(subject.ect, :date_of_birth).from(nil).to("3-2-1977")
          .and change(subject.ect, :trs_date_of_birth).from(nil).to("1977-02-03")
          .and change(subject.ect, :trs_first_name).from(nil).to("Kirk")
          .and change(subject.ect, :trs_last_name).from(nil).to("Van Houten")
      end
    end
  end
end
