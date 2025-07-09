describe Schools::TrainingProgramme do
  subject { described_class.new(school:, contract_period_id:) }

  let(:school) { FactoryBot.create(:school, urn: "123456") }
  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:contract_period_id) { contract_period.id }

  describe "#training_programme" do
    context "when school has no ects or mentors for the given contract period" do
      it "returns `not_yet_known`" do
        expect(subject.training_programme).to eq("not_yet_known")
      end
    end

    context "when school has ects or mentors for the given contract period" do
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

      context "when school has at least one mentor in training" do
        let(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period,
                            :active,
                            school:,
                            started_on: '2021-01-01')
        end
        let!(:training_period) do
          FactoryBot.create(:training_period,
                            :for_mentor,
                            mentor_at_school_period:,
                            school_partnership:,
                            started_on: mentor_at_school_period.started_on)
        end

        it "returns the correct `training_programme` choice" do
          expect(subject.training_programme).to eq("provider_led")
        end
      end

      context "when school has mentors not in training (only mentoring)" do
        let(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period,
                            :active,
                            school:,
                            started_on: '2021-01-01')
        end
        let(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period,
                            :active,
                            :provider_led,
                            school:,
                            started_on: '2021-01-01')
        end
        let!(:mentorship_period) do
          FactoryBot.create(:mentorship_period,
                            :active,
                            started_on: mentor_at_school_period.started_on,
                            mentor: mentor_at_school_period,
                            mentee: ect_at_school_period)
        end

        it "returns the correct `training_programme` choice" do
          expect(subject.training_programme).to eq("not_yet_known")
        end
      end

      context "when school has at least one expression of interest for training from a mentor" do
        let(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period,
                            :active,
                            school:,
                            started_on: '2021-01-01')
        end
        let!(:training_period) do
          FactoryBot.create(:training_period,
                            :for_mentor,
                            school_partnership_id: nil,
                            expression_of_interest: FactoryBot.create(:active_lead_provider, contract_period:),
                            mentor_at_school_period:,
                            started_on: mentor_at_school_period.started_on)
        end

        it "returns the correct `training_programme` choice" do
          expect(subject.training_programme).to eq("provider_led")
        end
      end

      context "when school has at least one ect in training" do
        context "when there is only `provider_led` as the ects training programmes" do
          let(:ect_at_school_period) do
            FactoryBot.create(:ect_at_school_period,
                              :active,
                              :provider_led,
                              school:,
                              started_on: '2021-01-01')
          end
          let!(:training_period) do
            FactoryBot.create(:training_period,
                              :for_ect,
                              ect_at_school_period:,
                              school_partnership:,
                              started_on: ect_at_school_period.started_on)
          end

          it "returns the correct `training_programme` choice" do
            expect(subject.training_programme).to eq("provider_led")
          end
        end

        context "when there is only `school_led` as the ects training programmes" do
          let(:ect_at_school_period) do
            FactoryBot.create(:ect_at_school_period,
                              :active,
                              :school_led,
                              school:,
                              started_on: '2021-01-01')
          end
          let!(:training_period) do
            FactoryBot.create(:training_period,
                              ect_at_school_period:,
                              school_partnership:,
                              started_on: '2022-01-01',
                              finished_on: '2022-06-01')
          end

          it "returns the correct `training_programme` choice" do
            expect(subject.training_programme).to eq("school_led")
          end
        end

        context "when there is a mix of `provider_led` and `school_led` as the ects training programmes" do
          let(:ect_at_school_period_1) do
            FactoryBot.create(:ect_at_school_period,
                              :active,
                              :provider_led,
                              school:,
                              started_on: '2021-01-01')
          end
          let!(:training_period_1) do
            FactoryBot.create(:training_period,
                              ect_at_school_period: ect_at_school_period_1,
                              school_partnership:,
                              started_on: '2022-01-01',
                              finished_on: '2022-06-01')
          end

          let(:ect_at_school_period_2) do
            FactoryBot.create(:ect_at_school_period,
                              :active,
                              :school_led,
                              school:,
                              started_on: '2021-01-01')
          end
          let!(:training_period) do
            FactoryBot.create(:training_period,
                              ect_at_school_period: ect_at_school_period_2,
                              school_partnership:,
                              started_on: '2022-01-01',
                              finished_on: '2022-06-01')
          end

          it "returns the correct `training_programme` choice" do
            expect(subject.training_programme).to eq("provider_led")
          end
        end
      end

      context "when school has at least one expression of interest for training from an ect" do
        let(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period,
                            :active,
                            :school_led,
                            school:,
                            started_on: '2021-01-01')
        end
        let!(:training_period) do
          FactoryBot.create(:training_period,
                            :for_ect,
                            school_partnership_id: nil,
                            expression_of_interest: FactoryBot.create(:active_lead_provider, contract_period:),
                            ect_at_school_period:,
                            started_on: ect_at_school_period.started_on)
        end

        it "returns the correct `training_programme` choice" do
          expect(subject.training_programme).to eq("school_led")
        end
      end
    end
  end
end
