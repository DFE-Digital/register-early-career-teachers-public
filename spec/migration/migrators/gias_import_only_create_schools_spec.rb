# rubocop:disable RSpec/AnyInstance
describe Migrators::GIASImportOnlyCreateSchools do
  def create_school(gias_school)
    FactoryBot.create(:school, gias_school:)
  end

  def create_gias_school
    FactoryBot.create(:gias_school)
  end

  it_behaves_like "a migrator", :gias_import, [], multiple_workers: true do
    def create_migration_resource = create_gias_school

    def create_resource(migration_resource) = create_school(migration_resource)

    def setup_failure_state
      urn = create_gias_school.urn
      allow_any_instance_of(GIAS::School).to receive(:create_school!).and_wrap_original do |original, *args|
        if original.receiver.urn == urn
          raise("Failed creating School!")
        else
          original.call(*args)
        end
      end
    end
  end

  describe "#migrate!" do
    let(:migrator) { described_class.new(worker: 0) }

    let!(:data_migration) { FactoryBot.create(:data_migration, model: :gias_import, worker: 0) }
    let!(:gias_school) { create_gias_school }

    it "creates a counterpart school" do
      expect { migrator.migrate! }.to change(::School, :count).by(1)
    end
  end
end

# rubocop:enable RSpec/AnyInstance
