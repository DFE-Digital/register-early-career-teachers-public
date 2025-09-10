RSpec.describe MermaidErd::Generator do
  subject(:generator) { described_class.new(config_path:, output_path:) }

  let(:config_path) { Rails.root.join('tmp/test_erd.yml') }
  let(:output_path) { Rails.root.join('tmp/test_domain_model.md') }

  before do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
    File.write(config_path, { 'exclude' => [] }.to_yaml)
  end

  after do
    FileUtils.rm_f(config_path)
    FileUtils.rm_f(output_path)
  end

  describe '#generate' do
    context 'with a basic model' do
      before { define_test_model(model_name: 'TestModel', table_name: 'users') }

      it 'writes a valid Mermaid ERD to the output file' do
        generator.generate

        contents = File.read(output_path)

        expect(contents).to include('```mermaid')
        expect(contents).to include('erDiagram')
        expect(contents).to include('TestModel {')
      end
    end

    context 'when the model is excluded in the pattern' do
      before do
        File.write(config_path, { 'exclude' => %w[TestModel] }.to_yaml)
        define_test_model(model_name: "TestModel", table_name: "users")
      end

      it 'omits excluded models from the ERD' do
        generator.generate

        expect(File.read(output_path)).not_to include('TestModel')
      end
    end

    context 'when the config file is missing' do
      it 'raises a meaningful error' do
        FileUtils.rm_f(config_path)

        expect {
          generator.generate
        }.to raise_error(/Missing config file/)
      end
    end

    context 'when the config file has invalid YAML' do
      before { File.write(config_path, 'invalid: [this is : bad') }

      it 'raises a YAML syntax error' do
        expect {
          generator.generate
        }.to raise_error(/YAML syntax error/)
      end
    end

    context 'when the environment is production' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'raises an error' do
        expect {
          generator.generate
        }.to raise_error(/only allowed in development and test/)
      end
    end

    context 'when the model has an integer array column' do
      before do
        ActiveRecord::Base.connection.create_table(:test_array_models, force: true) do |t|
          t.integer "contract_period_years", default: [], null: false, array: true
        end

        define_test_model(model_name: 'TestArrayModel', table_name: 'test_array_models')
      end

      after do
        ActiveRecord::Base.connection.drop_table(:test_array_models, if_exists: true)
      end

      it 'renders the array column as array[integer]' do
        generator.generate

        expect(File.read(output_path)).to include('array[integer] contract_period_years')
      end

      it 'does not render nested array brackets' do
        generator.generate
        expect(File.read(output_path)).not_to include('array[integer[]]')
      end
    end

    context 'when the model has a varchar array column' do
      before do
        ActiveRecord::Base.connection.create_table(:test_varchar_array_models, force: true) do |t|
          t.string :tags, array: true, default: [], null: false
        end
        define_test_model(model_name: 'TestVarcharArrayModel', table_name: 'test_varchar_array_models')
      end

      after { ActiveRecord::Base.connection.drop_table(:test_varchar_array_models, if_exists: true) }

      it 'renders a varchar array as array[string]' do
        generator.generate
        expect(File.read(output_path)).to include('array[string] tags')
      end
    end

    context 'when the model has a enum array column' do
      before do
        ActiveRecord::Base.connection.create_enum('declaration_types', %w[started retained-1 retained-2 completed])
        ActiveRecord::Base.connection.create_table(:test_enum_array_models, force: true) do |t|
          t.enum 'allowed_declaration_types', default: %w[started retained-1 retained-2 completed], array: true, enum_type: 'declaration_types'
        end
        define_test_model(model_name: 'TestEnumArrayModel', table_name: 'test_enum_array_models')
      end

      after do
        ActiveRecord::Base.connection.drop_table(:test_enum_array_models, if_exists: true)
        ActiveRecord::Base.connection.execute('DROP TYPE IF EXISTS declaration_types')
      end

      it 'renders an enum array as array[enum]' do
        generator.generate
        expect(File.read(output_path)).to include('array[enum] allowed_declaration_types')
      end
    end
  end

  def define_test_model(model_name:, table_name:)
    stub_const(model_name, Class.new(ApplicationRecord) do
      self.table_name = table_name
    end)
  end
end
