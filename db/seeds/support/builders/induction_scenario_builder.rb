# Example DSL for induction API scenario seeding
# Keyword block params for scenario:
# trn - calculated TRN based on client, scenario and index
# name - calculated teacher name based on client, scenario and index
# index - index of this iteration
#
# Induction::ScenarioBuilder.define do
#   scenario :new_ect_provider_led, id: 1 do |trn:, name:, index:|
#     # build seed stuff using TeacherHistories DSL
#     # ...
#   end
#
#   scenario :new_ect_school_led, id: 2 do |trn:, name:, index:|
#     # build seed stuff using TeacherHistories DSL
#     # ...
#   end
#
#   client "ECT Manager", trn_prefix: "90" do
#     seed :new_ect_provider_led, count: 5
#     seed :new_ect_school_led, count: 10
#   end
# end

module Induction
  class ScenarioBuilder
    Scenario = Data.define(:label, :id, :block)

    attr_reader :scenarios, :clients

    def self.define(&block)
      new.tap { |builder| builder.instance_eval(&block) }
    end

    def initialize
      @scenarios = {}
      @clients = []
      @trn_prefixes = []
    end

    def clear_trs_responses
      TRS::FakeTeacherStore.new.clear_all_options
    end

    def scenario(label, id:, &block)
      raise ArgumentError, "Invalid scenario ID: #{id}" unless (1..99).cover?(id) && id.is_a?(Integer)
      raise ArgumentError, "Duplicate scenario label: #{label}" if scenarios.key?(label)
      raise ArgumentError, "Duplicate scenario ID: #{id}" if scenarios.values.any? { |scenario| scenario.id == id }
      raise ArgumentError, "Missing scenario block: #{label}" unless block

      scenarios[label] = Scenario.new(label:, id:, block:)
    end

    def client(name, trn_prefix:, &block)
      trn_prefix = trn_prefix.to_s

      raise ArgumentError, "Invalid TRN prefix: #{trn_prefix}" unless trn_prefix.match?(/\A9\d\z/)
      raise ArgumentError, "Duplicate TRN prefix: #{trn_prefix}" if @trn_prefixes.include?(trn_prefix)

      @trn_prefixes << trn_prefix

      builder = ClientBuilder.new(name, trn_prefix:, scenarios:)
      builder.instance_eval(&block) if block_given?

      clients << builder.client if builder.client
    end
  end

  class ClientBuilder
    attr_reader :client, :trn_prefix

    def initialize(name, trn_prefix:, scenarios:)
      @name = name
      @trn_prefix = trn_prefix
      @scenarios = scenarios
      @seeded_scenarios = []
    end

    def oauth_client(grant_type: :authorization_code)
      print_seed_info("Seeding induction client '#{@name}'", colour: :green)

      return @client if @client

      @client = API::OAuth::Client.create!(
        name: @name,
        grant_types: [grant_type],
        **oauth_client_attributes
      )
    end

    def seed_all(count: 1)
      @scenarios.each_key { |label| seed(label, count:) }
    end

    def seed(label, count: 1)
      scenario = @scenarios.fetch(label)

      raise ArgumentError, "Invalid seed count: #{count}" unless count.is_a?(Integer) && (1..1000).cover?(count)
      raise ArgumentError, "Scenario already seeded: #{label}" if @seeded_scenarios.include?(label)

      print_seed_info(
        "Seeding induction scenario '#{label}' *#{count}* #{'time'.pluralize(count)} for #{@name}",
        colour: :yellow
      )

      ScenarioSeeder.new(scenario:, client_name: @name, trn_prefix:).seed(count:)

      @seeded_scenarios << label
    end

  private

    def oauth_client_attributes
      configuration = Rails.application.config.oauth_api_client_seed_credentials
      return { redirect_uris: ["https://example.com/callback"] } if configuration.nil?

      clients = JSON.parse(configuration, symbolize_names: true)
      raise ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain a JSON object" unless clients.is_a?(Hash)

      client_key = @name.parameterize(separator: "_").to_sym
      credentials = clients[client_key]
      raise ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain credentials for #{@name}" unless credentials.is_a?(Hash)

      missing_attributes = %i[client_id client_secret redirect_uris].select { |key| credentials[key].blank? }
      raise ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain #{missing_attributes.join(', ')} for #{@name}" if missing_attributes.any?

      client_id, client_secret, redirect_uris = credentials.values_at(:client_id, :client_secret, :redirect_uris)
      unless [client_id, client_secret].all?(String) && redirect_uris.is_a?(Array) && redirect_uris.all?(String)
        raise ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain strings for client_id and client_secret and an array of strings for redirect_uris for #{@name}"
      end

      {
        client_id:,
        client_secret_digest: Digest::SHA256.hexdigest(client_secret),
        redirect_uris:
      }
    rescue JSON::ParserError
      # Re-raise to avoid JSON parser errors exposing the raw credentials.
      raise ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain valid JSON", cause: nil
    end
  end

  class ScenarioSeeder
    attr_reader :scenario

    def initialize(scenario:, client_name:, trn_prefix:)
      @scenario = scenario
      @client_name = client_name
      @trn_prefix = trn_prefix
      @trs_options = {}
    end

    def seed(count: 1)
      count.times do |index|
        trn = teacher_trn(index)
        instance_exec(trn:, name: teacher_name(index), index:, &scenario.block)
        store_options_for_fake_trs_api(trn)
      end
    end

    def trs_responds_with(opts = {})
      @trs_options = opts
      print_seed_info("TRS response options '#{opts}'", indent: 2, colour: :magenta)
    end

  private

    def teacher_trn(index)
      sprintf("%s%02d%03d", @trn_prefix, scenario.id, index)
    end

    def teacher_name(index)
      first_name = @client_name.gsub(/[\s_]/, "-")
      last_name = scenario.label.to_s.tr("_", "-").capitalize

      "#{first_name} #{last_name}-#{index}"
    end

    def store_options_for_fake_trs_api(trn)
      if @trs_options.empty?
        fake_teacher_store.clear_options(trn)
      else
        fake_teacher_store.set_options(trn, **@trs_options)
      end
    end

    def fake_teacher_store
      @fake_teacher_store ||= TRS::FakeTeacherStore.new
    end
  end
end
