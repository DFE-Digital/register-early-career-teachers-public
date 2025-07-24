module OtherNamespace
  class TestUpdater
    def self.perform(model)
      model.update!(id: 0)
    end
  end
end

module Metadata
  class TestUpdater
    def self.perform(model)
      model.update!(id: 0)
    end
  end
end

RSpec.shared_examples "restricts updates to the Metadata namespace" do |factory|
  it "allows updates from within the Metadata namespace" do
    model = FactoryBot.create(factory)
    expect { Metadata::TestUpdater.perform(model) }.not_to raise_error
  end

  it "raises an error when updates are made from outside the Metadata namespace" do
    model = FactoryBot.create(factory)
    expected_message = "Updates to Metadata::SchoolLeadProviderContractPeriod are only allowed from the Metadata namespace"
    expect { OtherNamespace::TestUpdater.perform(model) }.to raise_error(Metadata::Base::UpdateRestrictedError, expected_message)
  end

  it "does not raise an error when bypassing update restrictions" do
    model = FactoryBot.create(factory)
    expect { model.class.bypass_update_restrictions { OtherNamespace::TestUpdater.perform(model) } }.not_to raise_error
  end
end
