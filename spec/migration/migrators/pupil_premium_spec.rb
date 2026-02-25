describe Migrators::PupilPremium do
  it_behaves_like "a migrator", :pupil_premium, %i[school contract_period] do
    let(:pupil_premium) { FactoryBot.create(:migration_pupil_premium) }

    def create_migration_resource
      FactoryBot.create(:migration_pupil_premium, pupil_premium_incentive: [true, false].sample, sparsity_incentive: [true, false].sample)
    end

    def create_resource(migration_resource)
      FactoryBot.create(:school, urn: migration_resource.school.urn, api_id: migration_resource.school.id)
      FactoryBot.create(:contract_period, year: migration_resource.start_year)
    end

    def setup_failure_state
      # Pupil premium where school does not exist
      create_migration_resource
    end

    describe "#migrate!" do
      it "creates the correct number of pupil premiums" do
        expect { instance.migrate! }.to change(PupilPremium, :count).by(2)
      end

      it "does not create duplicate pupil premiums" do
        instance.migrate!
        expect { instance.migrate! }.not_to change(PupilPremium, :count)
      end

      it "sets the pupil premium attributes correctly" do
        instance.migrate!

        pupil_premium = PupilPremium.find_by(school_urn: migration_resource1.school.urn.to_i, contract_period_year: migration_resource1.start_year)

        expect(pupil_premium).to have_attributes(
          school_urn: migration_resource1.school.urn.to_i,
          contract_period_year: migration_resource1.start_year,
          pupil_premium_uplift: migration_resource1.pupil_premium_incentive,
          sparsity_uplift: migration_resource1.sparsity_incentive
        )
      end
    end
  end
end
