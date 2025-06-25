def extract_terraform_version(file, match_on)
  return unless (matching_line = file.find { |f| f =~ match_on })

  matching_line.scan(%r{\d+\.\d+\.\d+}).first
end

describe 'Terraform versions' do
  versions_in_deployments = Dir.glob(Rails.root.join(".github/**/*.*"))
                                .index_with { |file| extract_terraform_version(File.open(file), /terraform_version/) }
                                .compact

  version_in_config = File.open(Rails.root.join("config/terraform/application/terraform.tf"))
                          .then { |version_line| extract_terraform_version(version_line, /required_version/) }

  versions_in_deployments.each do |file, version|
    context file do
      it "is at version #{version_in_config}" do
        expect(version).to eql(version_in_config)
      end
    end
  end

  context '.tool-versions' do
    version_in_tool_versions = File.open(Rails.root.join('.tool-versions')).then { |v| extract_terraform_version(v, /terraform/) }

    it "is at version #{version_in_tool_versions}" do
      expect(version_in_tool_versions).to eql(version_in_config)
    end
  end
end
