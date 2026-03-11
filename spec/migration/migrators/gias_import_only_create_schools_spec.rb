describe Migrators::GIASImport do
  def create_csv_row(status: "open")
    FactoryBot.build(:csv_school_row, status:)
  end

  def create_school_row(csv_row)
    GIAS::SchoolRow.new(csv_row)
  end

  def create_gias_school(csv_row)
    school_row = create_school_row(csv_row)
    FactoryBot.create(:gias_school, :with_school,
                      urn: school_row.urn,
                      administrative_district_name: school_row.administrative_district_name,
                      eligible: school_row.eligible,
                      in_england: school_row.in_england,
                      name: school_row.name,
                      phase_name: school_row.phase_name,
                      section_41_approved: school_row.section_41_approved,
                      status: school_row.status,
                      type_name: school_row.type_name,
                      ukprn: school_row.ukprn)
  end

  # rubocop:disable RSpec/AnyInstance
  def stub_gias_importer
    allow_any_instance_of(GIAS::Importer).to receive(:schools_file_path).and_return("schools.csv")
    allow_any_instance_of(GIAS::Importer).to receive(:school_links_file_path).and_return("school_links.csv")
    allow(File).to receive(:foreach).with("schools.csv", any_args).and_invoke(->(*_) { csv_rows })
    allow(File).to receive(:foreach).with("school_links.csv", any_args).and_invoke(->(*_) { [] })
    allow(CSV).to receive(:foreach).with("schools.csv", any_args).and_invoke(school_row_lambda)
    allow(CSV).to receive(:foreach).with("school_links.csv", any_args).and_invoke(school_link_row_lambda)
  end
  # rubocop:enable RSpec/AnyInstance

  let(:csv_rows) { [create_csv_row, create_csv_row] }
  let(:school_row_lambda) { ->(*_, &block) { csv_rows.each(&block) } }
  let(:school_link_row_lambda) { ->(*_, &block) { [].each(&block) } }

  before do
    stub_gias_importer
  end

  it_behaves_like "a migrator", :gias_import, [], multiple_workers: false do
    def create_migration_resource = create_csv_row

    def create_resource(migration_resource) = create_gias_school(migration_resource)

    def setup_failure_state
      csv_rows << FactoryBot.build(:csv_school_row, ukprn: csv_rows.first["UKPRN"])
      stub_gias_importer
    end
  end

  describe "#migrate!" do
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :gias_import, worker: 0) }
    let(:migrator) { described_class.new(worker: 0) }

    it "calls GIAS::Importer on each row to parse it and create a new school" do
      expect { migrator.migrate! }.to change(GIAS::School, :count).by(csv_rows.size)
    end
  end
end
