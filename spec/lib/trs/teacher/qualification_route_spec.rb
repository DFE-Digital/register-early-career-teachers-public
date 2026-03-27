RSpec.describe TRS::Teacher::QualificationRoute do
  let(:qts_via_pcge) do
    {
      "routeToProfessionalStatusId" => "08ca66bf-7602-452f-8985-712cd93916bc",
      "routeToProfessionalStatusType" => {
        "routeToProfessionalStatusTypeId" => "02a2135c-ac34-4481-a293-8a00aab7ee69",
        "name" => "PGCE ITT",
        "professionalStatusType" => "QualifiedTeacherStatus"
      },
      "status" => "Holds",
      "holdsFrom" => "2023-11-11",
      "trainingStartDate" => "2023-10-01",
      "degreeType" => { "degreeTypeId" => "40a85dd0-8512-438e-8040-649d7d677d07", "name" => "Postgraduate Certificate in Education" },
      "inductionExemption" => { "isExempt" => false, "exemptionReasons" => [] }
    }
  end

  let(:failed_qts_via_high_potential_itt) do
    {
      "routeToProfessionalStatusId" => "08ca66bf-7602-452f-8985-712cd93916bc",
      "routeToProfessionalStatusType" => {
        "routeToProfessionalStatusTypeId" => "02a2135c-ac34-4481-a293-8a00aab7ee69",
        "name" => "High Potential ITT",
        "professionalStatusType" => "QualifiedTeacherStatus"
      },
      "status" => "Failed",
      "inductionExemption" => { "isExempt" => false, "exemptionReasons" => [] }
    }
  end

  let(:eyts_via_assessment_only) do
    {
      "routeToProfessionalStatusId" => "ae03d1c9-23f5-4d1a-8aa9-83f0053b5cf9",
      "routeToProfessionalStatusType" => {
        "routeToProfessionalStatusTypeId" => "32017d68-9da4-43b2-ae91-4f24c68f6f78",
        "name" => "Assessment Only",
        "professionalStatusType" => "EarlyYearsTeacherStatus"
      },
      "status" => "Holds",
      "holdsFrom" => "2021-09-03",
      "trainingStartDate" => "2019-12-09",
      "inductionExemption" => { "isExempt" => false, "exemptionReasons" => [] }
    }
  end

  let(:qts_via_hei_historic) do
    {
      "routeToProfessionalStatusId" => "ae03d1c9-23f5-4d1a-8aa9-83f0053b5cf9",
      "routeToProfessionalStatusType" => {
        "routeToProfessionalStatusTypeId" => "32017d68-9da4-43b2-ae91-4f24c68f6f78",
        "name" => "HEI - Historic",
        "professionalStatusType" => "QualifiedTeacherStatus"
      },
      "status" => "Holds",
      "holdsFrom" => "2021-11-03",
      "trainingStartDate" => "2019-12-09",
      "degreeType" => { "degreeTypeId" => "dbb7c27b-8a27-4a94-908d-4b4404acebd5", "name" => "BA (Hons)" },
      "inductionExemption" => { "isExempt" => false, "exemptionReasons" => [] }
    }
  end

  let(:routes) { [qts_via_pcge, eyts_via_assessment_only] }

  describe "class#to_summary" do
    subject(:summary) { described_class.to_summary(routes) }

    it {
      expect(subject).to contain_exactly(
        "Holds QTS from 11 Nov 2023 via PGCE ITT",
        "Holds EYTS from 03 Sep 2021 via Assessment Only"
      )
    }
  end

  describe "to_summary" do
    subject(:summary) { summarizer.to_summary }

    let(:summarizer) { described_class.new(qualification_route) }

    context "when holding QTS via PCGE ITT" do
      let(:qualification_route) { qts_via_pcge }

      it { is_expected.to eq "Holds QTS from 11 Nov 2023 via PGCE ITT" }
    end

    context "when holding QTS via HEI Historic" do
      let(:qualification_route) { qts_via_hei_historic }

      it { is_expected.to eq "Holds QTS from 03 Nov 2021 via HEI - Historic" }
    end

    context "when holding EYTS via Assessment Only" do
      let(:qualification_route) { eyts_via_assessment_only }

      it { is_expected.to eq "Holds EYTS from 03 Sep 2021 via Assessment Only" }
    end

    context "when status is Failed and holdsFrom is absent" do
      let(:qualification_route) { failed_qts_via_high_potential_itt }

      it { is_expected.to eq "Failed QTS via High Potential ITT" }
    end
  end
end
