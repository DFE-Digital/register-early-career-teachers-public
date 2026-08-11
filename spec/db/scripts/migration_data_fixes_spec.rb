RSpec.describe "db/scripts/migration_data_fixes.rb" do
  subject(:run_script) do
    load Rails.root.join("db/scripts/migration_data_fixes.rb").to_s
  end

  let!(:first_training_period) { FactoryBot.create(:training_period) }
  let!(:second_training_period) { FactoryBot.create(:training_period) }

  let(:csv_log) { double("csv_log") }
  let(:logged_rows) { [] }

  def csv_row(training_period, action: "update")
    CSV::Row.new(
      %i[object_type object_id action attributes],
      [
        "TrainingPeriod",
        training_period.id.to_s,
        action,
        "withdrawn_at,2026-03-06 12:45:32,withdrawal_reason,moved_school",
      ]
    )
  end

  before do
    allow(CSV).to receive(:open).and_return(csv_log)
    allow(csv_log).to receive(:<<) { |row| logged_rows << row }
    allow(csv_log).to receive(:close)

    allow(Rails.logger).to receive(:warn)
  end

  context "when every row is valid" do
    before do
      allow(CSV).to receive(:foreach)
        .and_yield(csv_row(first_training_period))
        .and_yield(csv_row(second_training_period))
    end

    it "processes every row without reporting an error" do
      run_script

      expect(first_training_period.reload.withdrawal_reason).to eq("moved_school")
      expect(second_training_period.reload.withdrawal_reason).to eq("moved_school")
      expect(Rails.logger).not_to have_received(:warn)
      expect(logged_rows.map(&:last)).to eq(["errors", nil, nil])
      expect(csv_log).to have_received(:close)
    end
  end

  context "when a row fails" do
    let(:invalid_row) do
      csv_row(first_training_period, action: "unknown")
    end

    before do
      allow(CSV).to receive(:foreach)
        .and_yield(csv_row(first_training_period))
        .and_yield(invalid_row)
        .and_yield(csv_row(second_training_period))
    end

    it "reports the error and continues processing later rows" do
      run_script

      expect(first_training_period.reload.withdrawal_reason).to eq("moved_school")
      expect(second_training_period.reload.withdrawal_reason).to eq("moved_school")
      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("ArgumentError - Unknown action 'unknown'")
      )
      expect(logged_rows.map(&:last)).to eq(
        [
          "errors",
          nil,
          "Unknown action 'unknown'",
          nil,
        ]
      )
      expect(csv_log).to have_received(:close)
    end
  end
end
