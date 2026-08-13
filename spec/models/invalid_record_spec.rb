RSpec.describe InvalidRecord do
  describe "persistence" do
    it "persists a well-formed record" do
      record = described_class.create!(table_name: "teachers", record_id: 1, error_messages: "boom")

      expect(record).to be_persisted
    end
  end

  describe "database constraints" do
    it "requires a table_name" do
      expect { described_class.create!(record_id: 1, error_messages: "boom") }
        .to raise_error(ActiveRecord::NotNullViolation)
    end

    it "requires a record_id" do
      expect { described_class.create!(table_name: "teachers", error_messages: "boom") }
        .to raise_error(ActiveRecord::NotNullViolation)
    end

    it "requires error_messages" do
      expect { described_class.create!(table_name: "teachers", record_id: 1) }
        .to raise_error(ActiveRecord::NotNullViolation)
    end

    it "enforces uniqueness on table_name and record_id" do
      described_class.create!(table_name: "teachers", record_id: 1, error_messages: "boom")

      expect { described_class.create!(table_name: "teachers", record_id: 1, error_messages: "boom again") }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same record_id across different tables" do
      described_class.create!(table_name: "teachers", record_id: 1, error_messages: "a")

      expect { described_class.create!(table_name: "declarations", record_id: 1, error_messages: "b") }
        .not_to raise_error
    end
  end
end
