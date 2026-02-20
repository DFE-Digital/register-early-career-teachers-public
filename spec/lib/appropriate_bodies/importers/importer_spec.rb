RSpec.describe AppropriateBodies::Importers::Importer do
  subject(:importer) do
    described_class.new(appropriate_body_csv:, teachers_csv:, induction_period_csv:, dfe_sign_in_mapping_csv:, admin_csv:, cutoff_csv:)
  end

  let(:appropriate_body_csv) { Rails.root.join("tmp/import/appropriatebody.csv") }
  let(:teachers_csv) { Rails.root.join("tmp/import/teachers.csv") }
  let(:induction_period_csv) { Rails.root.join("tmp/import/inductionperiods.csv") }
  let(:dfe_sign_in_mapping_csv) { Rails.root.join("tmp/import/dfe-sign-in-mappings.csv") }
  let(:admin_csv) { Rails.root.join("tmp/import/admins.csv") }
  let(:cutoff_csv) { Rails.root.join("tmp/import/old-abs.csv") }

  it "work" do
    # expect(importer.import!).to eq()
    expect { importer.import! }.not_to raise_error
  end
end
