module API
  module ErrorDocumentationAncestorErrorStubConcern
    extend ActiveSupport::Concern

    included do
      validate :add_an_error
    end

  private

    def add_an_error
      errors.add(:add_error_in_ancestor, "Invalid")
    end
  end

  class ErrorDocumentationCompletenessStubService
    include ActiveModel::Model
    include API::ErrorDocumentationAncestorErrorStubConcern

    validates :rails_validator, presence: true
    validates :custom_validator, api_date_time_format: true

  private

    def add_error
      errors.add(:add_error, "Invalid")
    end
  end
end

RSpec.describe APIErrorDocumentation do
  subject(:documentation) { described_class.new }

  let(:alpha_service) { double(name: "API::Alpha") }

  def with_written_markdown
    Dir.mktmpdir do |directory|
      path = File.join(directory, "errors.md")
      documentation.write(path)

      yield File.read(path)
    end
  end

  describe "#add_error, #write" do
    it "does not write when the path is blank" do
      documentation.add_error(
        example: RSpec.current_example,
        service: alpha_service,
        attribute: :beta,
        message: "Invalid name"
      )

      expect(documentation.write(nil)).to be_nil
    end

    it "does not write when there are no errors" do
      Dir.mktmpdir do |directory|
        path = File.join(directory, "errors.md")

        expect(documentation.write(path)).to be_nil
        expect(File).not_to exist(path)
      end
    end

    it "infers the cause of the error from the example context" do
      example = double(example_group: double(parent_groups: [double(description: "when the token has expired")]))

      documentation.add_error(
        example:,
        service: alpha_service,
        attribute: :token,
        message: "Invalid token"
      )

      with_written_markdown do |markdown|
        expect(markdown).to include("| token | Invalid token | When the token has expired. |")
      end
    end

    it "normalizes datetime and contract period year in messages" do
      documentation.add_error(
        example: RSpec.current_example,
        service: alpha_service,
        attribute: :zebra,
        message: "Invalid at 2024-01-02T03:04:05Z for the 2025 contract period"
      )

      with_written_markdown do |markdown|
        expect(markdown).to include("| zebra | Invalid at <datetime> for the <contract period year> contract period | Unspecified. |")
      end
    end

    it "only reports the same error once" do
      documentation.add_error(
        example: RSpec.current_example,
        service: alpha_service,
        attribute: :name,
        message: "Invalid name"
      )
      documentation.add_error(
        example: RSpec.current_example,
        service: alpha_service,
        attribute: :name,
        message: "Invalid name"
      )

      with_written_markdown do |markdown|
        expect(markdown.scan(/\| name \| Invalid name \| Unspecified. \|/).size).to eq(1)
      end
    end

    it "reports the same error multiple times if it has multiple causes" do
      expired_example = double(example_group: double(parent_groups: [double(description: "when the token has expired")]))
      documentation.add_error(
        example: expired_example,
        service: alpha_service,
        attribute: :token,
        message: "Invalid token"
      )

      revoked_example = double(example_group: double(parent_groups: [double(description: "when the token has been revoked")]))
      documentation.add_error(
        example: revoked_example,
        service: alpha_service,
        attribute: :token,
        message: "Invalid token"
      )

      with_written_markdown do |markdown|
        expect(markdown.scan(/\| token \| Invalid token \| When the token has expired. \|/)).to be_present
        expect(markdown.scan(/\| token \| Invalid token \| When the token has been revoked. \|/)).to be_present
      end
    end

    it "writes sorted, grouped messages by service" do
      beta_service = double(name: "API::Beta::Service")

      documentation.add_error(
        example: RSpec.current_example,
        service: alpha_service,
        attribute: :name,
        message: "Invalid name"
      )
      documentation.add_error(
        example: RSpec.current_example,
        service: beta_service,
        attribute: :zebra,
        message: "Invalid zebra"
      )
      documentation.add_error(
        example: RSpec.current_example,
        service: beta_service,
        attribute: :tiger,
        message: "Invalid tiger"
      )
      documentation.add_error(
        example: RSpec.current_example,
        service: alpha_service,
        attribute: :name,
        message: "Another invalid name"
      )

      with_written_markdown do |markdown|
        expect(markdown).to eq(<<~MARKDOWN.chomp)
          # API errors

          ## Alpha

          | Attribute | Message | Cause |
          | --- | --- | --- |
          | name | Another invalid name | Unspecified. |
          | name | Invalid name | Unspecified. |

          ## Beta → Service

          | Attribute | Message | Cause |
          | --- | --- | --- |
          | tiger | Invalid tiger | Unspecified. |
          | zebra | Invalid zebra | Unspecified. |
        MARKDOWN
      end
    end
  end

  describe "#verify_completeness!" do
    let(:service) { API::ErrorDocumentationCompletenessStubService }

    it "does not raise when all errors are documented" do
      attributes = %i[add_error add_error_in_ancestor rails_validator custom_validator]
      attributes.each do |attribute|
        documentation.add_error(
          example: RSpec.current_example,
          service:,
          attribute:,
          message: "Invalid"
        )
      end

      expect { documentation.verify_completeness! }.not_to raise_error
    end

    it "does not raise if no errors have been documented" do
      expect { documentation.verify_completeness! }.not_to raise_error
    end

    it "raises with the attributes missing from the documentation" do
      documentation.add_error(
        example: RSpec.current_example,
        service:,
        attribute: :add_error,
        message: "Invalid"
      )

      expect { documentation.verify_completeness! }
        .to raise_error(
          described_class::UndocumentedError,
          "Missing validation error documentation for #{service}: add_error_in_ancestor, rails_validator, custom_validator"
        )
    end
  end
end
