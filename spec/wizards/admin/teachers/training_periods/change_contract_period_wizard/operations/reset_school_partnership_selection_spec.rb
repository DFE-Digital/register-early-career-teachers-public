RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Operations::ResetSchoolPartnershipSelection do
  subject(:operation) { described_class.new(repository:, step: instance_double(Object)) }

  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  before { repository.write(contract_period_year: 2026, school_partnership_id: 123) }

  it "clears the selected partnership" do
    expect(operation.execute).to eq(success: true)
    expect(repository.read).to eq(contract_period_year: 2026, school_partnership_id: nil)
  end
end
