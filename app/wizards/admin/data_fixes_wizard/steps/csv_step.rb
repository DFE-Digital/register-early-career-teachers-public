module Admin::DataFixesWizard::Steps
  class CSVStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[csv_string]

    attribute :csv_string, :string, default: ""
    attribute :parsed_rows

    validates :csv_string, presence: { message: "CSV can’t be blank" }
  end
end
