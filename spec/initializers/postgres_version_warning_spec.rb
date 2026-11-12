RSpec.describe PostgresVersionWarning do
  describe ".warn_if_outdated" do
    subject(:warn_if_outdated) do
      described_class.warn_if_outdated(logger:, environment:, connection_pool:)
    end

    let(:logger) { instance_double(Logger, warn: nil) }
    let(:environment) { ActiveSupport::StringInquirer.new("development") }
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }

    it "warns when PostgreSQL is older than v18 in development" do
      allow(connection_pool).to receive(:with_connection).and_return(170_011)

      warn_if_outdated

      expect(logger).to have_received(:warn).with(
        "PostgreSQL v18 or newer is recommended in development and test. Detected database_version=170011."
      )
    end

    it "does not warn when PostgreSQL is v18 or newer" do
      allow(connection_pool).to receive(:with_connection).and_return(180_003)

      warn_if_outdated

      expect(logger).not_to have_received(:warn)
    end

    it "does nothing in production" do
      allow(connection_pool).to receive(:with_connection).and_return(170_011)

      described_class.warn_if_outdated(
        logger:,
        environment: ActiveSupport::StringInquirer.new("production"),
        connection_pool:
      )

      expect(logger).not_to have_received(:warn)
    end

    it "warns when ActiveRecord::ConnectionNotEstablished is raised" do
      allow(connection_pool).to receive(:with_connection).and_raise(
        ActiveRecord::ConnectionNotEstablished.new("connection failed")
      )

      warn_if_outdated

      expect(logger).to have_received(:warn).with(
        "Unable to determine PostgreSQL database version during boot: ActiveRecord::ConnectionNotEstablished: connection failed"
      )
    end

    it "warns when ActiveRecord::NoDatabaseError is raised" do
      allow(connection_pool).to receive(:with_connection).and_raise(
        ActiveRecord::NoDatabaseError.new("database missing")
      )

      warn_if_outdated

      expect(logger).to have_received(:warn).with(
        "Unable to determine PostgreSQL database version during boot: ActiveRecord::NoDatabaseError: database missing"
      )
    end
  end
end
