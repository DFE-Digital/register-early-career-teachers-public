describe Migration::Partnership, type: :model do
  describe "#forbidden?" do
    subject { partnership.forbidden? }

    let(:partnership) { FactoryBot.create(:migration_partnership) }

    context "when there is a matching provider relationship" do
      before do
        FactoryBot.create(:migration_provider_relationship,
                          lead_provider: partnership.lead_provider,
                          delivery_partner: partnership.delivery_partner,
                          cohort: partnership.cohort)
      end

      it { is_expected.to be_falsey }
    end

    context "when there is not a matching provider relationship" do
      it { is_expected.to be_truthy }
    end
  end
end
