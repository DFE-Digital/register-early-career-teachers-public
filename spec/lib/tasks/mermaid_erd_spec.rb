describe 'ERD tasks' do
  describe 'erd:generate' do
    let(:generator) { instance_double(MermaidErd::Generator) }

    before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development')) }

    it 'calls the MermaidErd::Generator' do
      allow(MermaidErd::Generator).to receive(:new).with(
        config_path: Rails.root.join('config/mermaid_erd.yml'),
        output_path: Rails.root.join('documentation/domain-model.md')
      ).and_return(generator)

      expect(generator).to receive(:generate)

      Rake::Task['erd:generate'].invoke
    end
  end
end
