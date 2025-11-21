describe Schools::DecoratedSchool do
  let(:school) { FactoryBot.create(:school) }
  let(:decorated_school) { Schools::DecoratedSchool.new(school) }
  let(:contract_period) { FactoryBot.create(:contract_period) }

  it "decorates a School" do
    expect(decorated_school.__getobj__).to be_a(School)
  end

  describe "#latest_registration_choices" do
    let(:fake_latest_registration_choices) { double("Schools::LatestRegistrationChoices") }

    before do
      allow(Schools::LatestRegistrationChoices).to receive(:new)
                                                     .with(school: decorated_school, contract_period:)
                                                     .and_return(fake_latest_registration_choices)
    end

    it "returns a Schools::LatestRegistrationChoices object" do
      expect(decorated_school.latest_registration_choices(contract_period:)).to eql(fake_latest_registration_choices)
    end
  end

  describe "#has_partnership_with?" do
    subject { decorated_school.has_partnership_with?(lead_provider:, contract_period:) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:fake_partnership_check) { double("SchoolPartnerships::Search", exists?: true) }

    before do
      allow(SchoolPartnerships::Search).to receive(:new)
                                             .with(lead_provider:, contract_period:)
                                             .and_return(fake_partnership_check)
    end

    it "creates a SchoolPartnerships::Search and calls #exists?" do
      expect(subject).to be(true)
      expect(fake_partnership_check).to have_received(:exists?).once
      expect(SchoolPartnerships::Search).to have_received(:new).with(lead_provider:, contract_period:)
    end
  end

  describe "#show_previous_programme_choices_row?" do
    subject { decorated_school.show_previous_programme_choices_row?(wizard) }

    let(:wizard) { double("wizard") }

    context "when the school has no last programme choices" do
      before do
        allow(school).to receive(:last_programme_choices?).and_return(false)
        allow(Schools::RegisterECTWizard::UsePreviousECTChoicesStep).to receive(:new)
      end

      it "returns false" do
        expect(subject).to be(false)
      end

      it "does not instantiate the UsePreviousECTChoicesStep" do
        subject
        expect(Schools::RegisterECTWizard::UsePreviousECTChoicesStep).not_to have_received(:new)
      end
    end

    context "when the school has last programme choices" do
      let(:step_double) { double("UsePreviousECTChoicesStep", allowed?: allowed) }

      before do
        allow(school).to receive(:last_programme_choices?).and_return(true)
        allow(Schools::RegisterECTWizard::UsePreviousECTChoicesStep).to receive(:new)
                                                                          .with(wizard:)
                                                                          .and_return(step_double)
      end

      context "and the reuse step is allowed" do
        let(:allowed) { true }
        let(:ect) { double("ect", use_previous_ect_choices: ect_uses_previous) }

        before do
          allow(wizard).to receive(:ect).and_return(ect)
        end

        context "and the ECT chose to reuse previous choices" do
          let(:ect_uses_previous) { true }

          it "returns true" do
            expect(subject).to be(true)
          end
        end

        context "and the ECT choses not to reuse previous choices" do
          let(:ect_uses_previous) { false }

          it "returns false" do
            expect(subject).to be(false)
          end
        end
      end

      context "and the reuse step is not allowed" do
        let(:allowed) { false }

        it "returns false" do
          expect(subject).to be(false)
        end
      end
    end
  end
end
