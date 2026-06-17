describe TeacherHistories::TrainingPeriodBuilder do
  let(:trn) { "1122334" }
  let(:trs_first_name) { "Clark" }
  let(:trs_last_name) { "Gable" }
  let(:full_name) { "#{trs_first_name} #{trs_last_name}" }

  let(:school) { FactoryBot.create(:school) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead provider one") }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Delivery partner one") }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
  let!(:milestone_started) { FactoryBot.create(:milestone, :started, schedule:, start_date: Date.new(2025, 6, 15), milestone_date: Date.new(2025, 12, 10)) }
  let!(:milestone_retained_1) { FactoryBot.create(:milestone, :retained_1, schedule:, start_date: Date.new(2025, 8, 15), milestone_date: Date.new(2026, 3, 10)) }
  let!(:milestone_retained_2) { FactoryBot.create(:milestone, :retained_2, schedule:, start_date: Date.new(2026, 6, 15), milestone_date: Date.new(2026, 8, 15)) }
  let!(:milestone_completed) { FactoryBot.create(:milestone, :completed, schedule:, start_date: Date.new(2026, 10, 15), milestone_date: Date.new(2026, 12, 18)) }

  let(:contract) { FactoryBot.create(:contract, active_lead_provider:) }
  let!(:statement) { FactoryBot.create(:statement, contract:) }

  describe "adding declarations" do
    context "ECT declarations" do
      let(:declarations) { teacher.reload.ect_at_school_periods[0].training_periods[0].declarations }

      describe "#declaration" do
        let(:teacher) do
          school_inner = school
          lead_provider_inner = lead_provider
          schedule_inner = schedule

          TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
            ect_at_school_period(school_inner, "2025-01-01 -> 2026-03-03") do
              training_period(lead_provider_inner, 2025, "2025-01-03 -> 2026-03-01", schedule: schedule_inner) do
                declaration("started",    "2025-12-10", :paid)
                declaration("retained-1", "2026-03-10", :payable)
                declaration("retained-2", "2026-08-15", :no_payment)
              end
            end
          end
        end

        it "creates a teacher with an ECT at school period, training period and three declarations" do
          expect(declarations.count).to be(3)
        end

        it "creates declarations with the right states" do
          expect(declarations.map(&:payment_status)).to match_array(%w[paid payable no_payment])
        end
      end

      describe "#declarations" do
        context "using an array" do
          let(:teacher) do
            school_inner = school
            lead_provider_inner = lead_provider
            schedule_inner = schedule

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              ect_at_school_period(school_inner, "2025-01-01 -> 2026-03-03") do
                training_period(lead_provider_inner, 2025, "2025-01-03 -> 2026-03-01", schedule: schedule_inner) do
                  declarations(%w[started retained-1])
                end
              end
            end
          end

          it "creates a teacher with an ECT at school period, training period and two declarations" do
            expect(declarations.count).to be(2)
          end

          it "creates declarations with the right states" do
            expect(declarations.map(&:declaration_type)).to match_array(%w[started retained-1])
          end
        end

        context "using a hash" do
          let(:teacher) do
            school_inner = school
            lead_provider_inner = lead_provider
            schedule_inner = schedule

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              ect_at_school_period(school_inner, "2025-01-01 -> 2026-03-03") do
                training_period(lead_provider_inner, 2025, "2025-01-03 -> 2026-03-01", schedule: schedule_inner) do
                  declarations({ "started" => :paid, "retained-1" => :voided })
                end
              end
            end
          end

          it "creates a teacher with an ECT at school period, training period and two declarations" do
            expect(declarations.count).to be(2)
          end

          it "creates declarations with the right states" do
            expect(declarations.map(&:declaration_type)).to match_array(%w[started retained-1])
          end
        end
      end
    end

    context "mentor declarations" do
      describe "#declaration" do
        let(:teacher) do
          school_inner = school
          lead_provider_inner = lead_provider

          TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
            mentor_at_school_period(school_inner, "2025-01-01 -> 2026-03-03") do
              training_period(lead_provider_inner, 2025, "2025-01-03 -> 2026-03-01") do
                declaration("started",   "2025-12-05", :paid)
                declaration("completed", "2026-12-05", :payable)
              end
            end
          end
        end

        let(:declarations) { teacher.reload.mentor_at_school_periods[0].training_periods[0].declarations }

        it "creates a teacher with an mentor at school period, training period and three declarations" do
          expect(declarations.count).to be(2)
        end

        it "creates declarations with the right states" do
          expect(declarations.map(&:payment_status)).to match_array(%w[paid payable])
        end
      end

      describe "#declarations" do
        context "using an array" do
          let(:teacher) do
            school_inner = school
            lead_provider_inner = lead_provider
            schedule_inner = schedule

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              mentor_at_school_period(school_inner, "2025-01-01 -> 2026-03-03") do
                training_period(lead_provider_inner, 2025, "2025-01-03 -> 2026-03-01", schedule: schedule_inner) do
                  declarations(%w[started completed])
                end
              end
            end
          end

          let(:declarations) { teacher.reload.mentor_at_school_periods[0].training_periods[0].declarations }

          it "creates a teacher with an mentor at school period, training period and two declarations" do
            expect(declarations.count).to be(2)
          end

          it "creates declarations with the right states" do
            expect(declarations.map(&:declaration_type)).to match_array(%w[started completed])
          end
        end

        context "using a hash" do
          let(:teacher) do
            school_inner = school
            lead_provider_inner = lead_provider
            schedule_inner = schedule

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              mentor_at_school_period(school_inner, "2025-01-01 -> 2026-03-03") do
                training_period(lead_provider_inner, 2025, "2025-01-03 -> 2026-03-01", schedule: schedule_inner) do
                  declarations({ "started" => :paid, "completed" => :voided })
                end
              end
            end
          end

          let(:declarations) { teacher.reload.mentor_at_school_periods[0].training_periods[0].declarations }

          it "creates a teacher with an mentor at school period, training period and two declarations" do
            expect(declarations.count).to be(2)
          end

          it "creates declarations with the right states" do
            expect(declarations.map(&:declaration_type)).to match_array(%w[started completed])
          end
        end
      end
    end
  end
end
