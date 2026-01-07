RSpec.describe AppropriateBodies::Importers::Importer do
  subject(:importer) do
    described_class.new(appropriate_body_csv:, teachers_csv:, induction_period_csv:, dfe_sign_in_mapping_csv:, dqt_csv:)
  end

  let(:appropriate_body_csv) { Rails.root.join("tmp/import/appropriatebody.csv") }
  let(:teachers_csv) { Rails.root.join("tmp/import/teachers.csv") }
  let(:induction_period_csv) { Rails.root.join("tmp/import/inductionperiods.csv") }
  let(:dfe_sign_in_mapping_csv) { Rails.root.join("tmp/import/dfe-sign-in-mappings.csv") }
  let(:dqt_csv) { Rails.root.join("tmp/import/old-abs.csv") }

  it "imports expected data" do
    expect { importer.import! }.not_to raise_error

    # Total imports
    expect(AppropriateBodyPeriod.count).to eq(1)
    expect(Teacher.count).to eq(1)
    expect(InductionPeriod.count).to eq(1)
    expect(InductionExtension.count).to eq(1)
    expect(Event.count).to eq(1)

    # fails if rerun
    expect { importer.import! }.to raise_error
  end
end
