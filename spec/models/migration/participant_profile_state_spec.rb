describe Migration::ParticipantProfileState, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:participant_profile) }
    it { is_expected.to belong_to(:cpd_lead_provider) }
    it { is_expected.to have_one(:lead_provider).through(:cpd_lead_provider) }
  end

  describe "#deferred?" do
    subject { record.deferred? }

    let(:record) { FactoryBot.build(:migration_participant_profile_state, state:) }

    context 'when state is "deferred"' do
      let(:state) { "deferred" }

      it { is_expected.to be true }
    end

    context 'when state not "deferred"' do
      let(:state) { "active" }

      it { is_expected.to be false }
    end
  end

  describe "#withdrawn?" do
    subject { record.withdrawn? }

    let(:record) { FactoryBot.build(:migration_participant_profile_state, state:) }

    context 'when state is "withdrawn"' do
      let(:state) { "withdrawn" }

      it { is_expected.to be true }
    end

    context 'when state not "withdrawn"' do
      let(:state) { "active" }

      it { is_expected.to be false }
    end
  end
end
