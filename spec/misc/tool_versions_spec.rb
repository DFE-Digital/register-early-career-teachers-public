describe 'Tool versions' do
  let(:tool_versions) { File.readlines(Rails.root.join('.tool-versions'), chomp: true).map(&:split).to_h }

  describe 'Ruby versions' do
    let(:ruby_version) { File.read(Rails.root.join('.ruby-version')).chomp }
    let(:tool_versions_ruby_version) { tool_versions['ruby'] }

    specify 'the version number in .ruby-version and .tool-versions matches' do
      expect(ruby_version).to eql(tool_versions_ruby_version)
    end
  end

  describe 'Node versions' do
    let(:node_version) { File.read(Rails.root.join('.node-version')).chomp }
    let(:tool_versions_node_version) { tool_versions['nodejs'] }

    specify 'the version number in .node-version and .tool-versions matches' do
      expect(node_version).to eql(tool_versions_node_version)
    end
  end
end
