RSpec.describe "Multiple induction records" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1234567",
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          { start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 2, 2) },
          { start_date: Date.new(2024, 2, 3), end_date: :ignore }
        ]
      },
    }
  end

  let(:expected_output) do
    {
      teacher: hash_including(
        trn: "1234567",
        api_ect_training_record_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        ect_at_school_periods: [
          hash_including(started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 2, 2)),
          hash_including(started_on: Date.new(2024, 2, 3), finished_on: nil),
        ]
      ),
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  it "produces the expected output" do
    expect(actual_output).to include(expected_output)
  end

  # subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }
  #
  # let(:school_urn_1) { "123456" }
  # let(:school_urn_2) { "789012" }
  # let(:lead_provider_1) { Types::LeadProviderInfo.new(ecf1_id: SecureRandom.uuid, name: "Lead Provider A") }
  # let(:lead_provider_2) { Types::LeadProviderInfo.new(ecf1_id: SecureRandom.uuid, name: "Lead Provider B") }
  # let(:delivery_partner_1) { Types::DeliveryPartnerInfo.new(ecf1_id: SecureRandom.uuid, name: "Delivery Partner A") }
  # let(:delivery_partner_2) { Types::DeliveryPartnerInfo.new(ecf1_id: SecureRandom.uuid, name: "Delivery Partner B") }
  #
  # def build_induction_record(school_urn:, start_date:, end_date:, lead_provider_info: nil, delivery_partner_info: nil, training_programme: :full_induction_programme, training_status: "active")
  #   training_provider_info = if lead_provider_info || delivery_partner_info
  #                              FactoryBot.build(:ecf1_teacher_history_training_provider_info,
  #                                               lead_provider_info:,
  #                                               delivery_partner_info:)
  #                            end
  #
  #   FactoryBot.build(
  #     :ecf1_teacher_history_induction_record_row,
  #     school_urn:,
  #     start_date:,
  #     end_date:,
  #     training_programme:,
  #     training_status:,
  #     training_provider_info:,
  #     created_at: start_date.to_time
  #   )
  # end
  #
  # describe "school grouping" do
  #   context "when multiple consecutive IRs are at the same school" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               lead_provider_info: lead_provider_1,
  #               delivery_partner_info: delivery_partner_1
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               lead_provider_info: lead_provider_1,
  #               delivery_partner_info: delivery_partner_1
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates one ECTAtSchoolPeriodRow for the school" do
  #       expect(subject.ect_at_school_period_rows.count).to eq(1)
  #     end
  #
  #     it "uses the first IR's start date for the school period" do
  #       expect(subject.ect_at_school_period_rows.first.started_on).to eq(Date.new(2023, 9, 1))
  #     end
  #
  #     it "uses the last IR's end date for the school period" do
  #       expect(subject.ect_at_school_period_rows.first.finished_on).to eq(Date.new(2024, 8, 31))
  #     end
  #
  #     it "creates one training period (since training didn't change)" do
  #       expect(subject.ect_at_school_period_rows.first.training_period_rows.count).to eq(1)
  #     end
  #
  #     it "extends the training period to cover both IRs" do
  #       training_period = subject.ect_at_school_period_rows.first.training_period_rows.first
  #       expect(training_period.started_on).to eq(Date.new(2023, 9, 1))
  #       expect(training_period.finished_on).to eq(Date.new(2024, 8, 31))
  #     end
  #   end
  #
  #   context "when IRs are at different schools" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31)
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_2,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31)
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates separate ECTAtSchoolPeriodRows for each school" do
  #       expect(subject.ect_at_school_period_rows.count).to eq(2)
  #     end
  #
  #     it "assigns correct schools to each period" do
  #       urns = subject.ect_at_school_period_rows.map { |row| row.school.urn }
  #       expect(urns).to eq([school_urn_1, school_urn_2])
  #     end
  #   end
  #
  #   context "when teacher returns to a previous school" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31)
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_2,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 6, 30)
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 9, 1),
  #               end_date: Date.new(2025, 8, 31)
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates three separate school periods (not grouped by URN)" do
  #       expect(subject.ect_at_school_period_rows.count).to eq(3)
  #     end
  #
  #     it "maintains chronological order" do
  #       urns = subject.ect_at_school_period_rows.map { |row| row.school.urn }
  #       expect(urns).to eq([school_urn_1, school_urn_2, school_urn_1])
  #     end
  #   end
  # end
  #
  # describe "training period changes within a school" do
  #   context "when lead provider changes" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               lead_provider_info: lead_provider_1,
  #               delivery_partner_info: delivery_partner_1
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               lead_provider_info: lead_provider_2,
  #               delivery_partner_info: delivery_partner_1
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates one school period" do
  #       expect(subject.ect_at_school_period_rows.count).to eq(1)
  #     end
  #
  #     it "creates two training periods" do
  #       expect(subject.ect_at_school_period_rows.first.training_period_rows.count).to eq(2)
  #     end
  #
  #     it "assigns correct lead providers to each training period" do
  #       training_periods = subject.ect_at_school_period_rows.first.training_period_rows
  #       expect(training_periods[0].lead_provider_info).to eq(lead_provider_1)
  #       expect(training_periods[1].lead_provider_info).to eq(lead_provider_2)
  #     end
  #   end
  #
  #   context "when delivery partner changes" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               lead_provider_info: lead_provider_1,
  #               delivery_partner_info: delivery_partner_1
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               lead_provider_info: lead_provider_1,
  #               delivery_partner_info: delivery_partner_2
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates two training periods" do
  #       expect(subject.ect_at_school_period_rows.first.training_period_rows.count).to eq(2)
  #     end
  #   end
  #
  #   context "when training programme changes" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               training_programme: :full_induction_programme
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               training_programme: :core_induction_programme
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates two training periods" do
  #       expect(subject.ect_at_school_period_rows.first.training_period_rows.count).to eq(2)
  #     end
  #
  #     it "assigns correct training programmes" do
  #       training_periods = subject.ect_at_school_period_rows.first.training_period_rows
  #       expect(training_periods[0].training_programme).to eq("provider_led")
  #       expect(training_periods[1].training_programme).to eq("school_led")
  #     end
  #   end
  #
  #   context "when participant resumes from deferred status" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               lead_provider_info: lead_provider_1,
  #               training_status: "deferred"
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               lead_provider_info: lead_provider_1,
  #               training_status: "active"
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates two training periods (new period when resuming)" do
  #       expect(subject.ect_at_school_period_rows.first.training_period_rows.count).to eq(2)
  #     end
  #
  #     it "marks the first training period as deferred" do
  #       first_training_period = subject.ect_at_school_period_rows.first.training_period_rows.first
  #       expect(first_training_period.deferred_at).to be_present
  #     end
  #   end
  #
  #   context "when participant resumes from withdrawn status" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.ect = FactoryBot.build(:ecf1_teacher_history_ect) do |ect|
  #           ect.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               lead_provider_info: lead_provider_1,
  #               training_status: "withdrawn"
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               lead_provider_info: lead_provider_1,
  #               training_status: "active"
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates two training periods (new period when resuming)" do
  #       expect(subject.ect_at_school_period_rows.first.training_period_rows.count).to eq(2)
  #     end
  #
  #     it "marks the first training period as withdrawn" do
  #       first_training_period = subject.ect_at_school_period_rows.first.training_period_rows.first
  #       expect(first_training_period.withdrawn_at).to be_present
  #     end
  #   end
  # end
  #
  # describe "mentor school grouping" do
  #   context "when multiple consecutive IRs are at the same school with provider_led training" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.mentor = FactoryBot.build(:ecf1_teacher_history_mentor) do |mentor|
  #           mentor.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 1, 31),
  #               lead_provider_info: lead_provider_1,
  #               training_programme: :full_induction_programme
  #             ),
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2024, 2, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               lead_provider_info: lead_provider_1,
  #               training_programme: :full_induction_programme
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates one MentorAtSchoolPeriodRow for the school" do
  #       expect(subject.mentor_at_school_period_rows.count).to eq(1)
  #     end
  #
  #     it "creates one training period (since training didn't change)" do
  #       expect(subject.mentor_at_school_period_rows.first.training_period_rows.count).to eq(1)
  #     end
  #   end
  #
  #   context "when mentor has non-provider_led training" do
  #     let(:ecf1_teacher_history) do
  #       FactoryBot.build(:ecf1_teacher_history) do |history|
  #         history.mentor = FactoryBot.build(:ecf1_teacher_history_mentor) do |mentor|
  #           mentor.induction_records = [
  #             build_induction_record(
  #               school_urn: school_urn_1,
  #               start_date: Date.new(2023, 9, 1),
  #               end_date: Date.new(2024, 8, 31),
  #               training_programme: :core_induction_programme
  #             )
  #           ]
  #         end
  #       end
  #     end
  #
  #     it "creates mentor at school period" do
  #       expect(subject.mentor_at_school_period_rows.count).to eq(1)
  #     end
  #
  #     it "does not create training periods (mentors only have provider_led training periods)" do
  #       expect(subject.mentor_at_school_period_rows.first.training_period_rows.count).to eq(0)
  #     end
  #   end
  # end
end
