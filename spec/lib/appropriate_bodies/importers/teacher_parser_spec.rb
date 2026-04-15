RSpec.describe AppropriateBodies::Importers::TeacherParser do
  subject(:parser) do
    described_class.new(
      data_csv: sample_teacher_data,
      trns_with_induction_periods:
    )
  end

  let(:sample_teacher_data) do
    <<~CSV
      trn,first_name,last_name,extension_length,extension_length_unit,induction_status
      1234567,Faye,Tozer,,,RequiredToComplete
      2345678,Lisa,Scott-Lee,,,InProgress
      3456789,Lee,Latchford-Evans,,,InProgress
      4567890,Ian,Watkins,,,Exempt
      5678901,Rachel,Stevens,,,Passed
      6789012,Tina,Barrett,,,Passed
      7890123,Paul,Cattermole,,,Failed
      8901234,Jon,Lee,,,Failed
      9012345,Bradley,McIntosh,,,FailedInWales
      0123456,Jo,O'Meara,,,Passed
      7777777,Hannah,Spearritt,,,None
    CSV
  end

  let(:trns_with_induction_periods) do
    %w[1234567 2345678 7890123 9012345 5678901 7777777]
  end

  let(:filtered_trns) { parser.rows.map(&:trn) }

  it "selects only TRNs with induction periods if their status is not ongoing" do
    expect(filtered_trns).to include(*%w[7890123 9012345 5678901 7777777])
  end

  it "rejects TRNs with induction periods if their status is ongoing" do
    expect(filtered_trns).not_to include(*%w[1234567 2345678])
  end

  it "rejects TRNs without induction periods" do
    expect(filtered_trns).not_to include("4567890")
  end

  describe "extension lengths" do
    let(:sample_teacher_data) do
      <<~CSV
        trn,first_name,last_name,extension_length,extension_length_unit,induction_status
        5678901,Rachel,Stevens,9,Years,Passed
        7890123,Paul,Cattermole,14,Months,Failed
        9012345,Bradley,McIntosh,20,Weeks,FailedInWales
        7777777,Hannah,Spearritt,200,Days,None
      CSV
    end

    let(:trns_with_induction_periods) { %w[5678901 7890123 9012345 7777777] }

    it "converts 9 years to be 27.0 terms" do
      expect(parser.rows.find { |r| r.trn == "5678901" }.extension_terms).to be(27.0)
    end

    it "converts 14 months to be 4.7 terms" do
      expect(parser.rows.find { |r| r.trn == "7890123" }.extension_terms).to be(4.7)
    end

    it "converts 20 weeks to be 1.5 terms" do
      expect(parser.rows.find { |r| r.trn == "9012345" }.extension_terms).to be(1.5)
    end

    it "converts 200 days to be 3.1" do
      expect(parser.rows.find { |r| r.trn == "7777777" }.extension_terms).to be(3.1)
    end
  end
end
