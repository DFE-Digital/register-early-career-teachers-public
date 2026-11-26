# @example DSL for induction API scenario seeding
#
#   Induction::ScenarioBuilder.define do
#     scenario :new_ect_provider_led, id: 1 do |trn:, name:, index:|
#       # build seed stuff using TeacherHistories DSL
#       # ...
#     end
#
#     scenario :new_ect_school_led, id: 2 do |trn:, name:, index:|
#       # build seed stuff using TeacherHistories DSL
#       # ...
#     end
#
#     client "ECT Manager", trn_prefix: "90" do
#       seed :new_ect_provider_led, count: 5
#       seed :new_ect_school_led, count: 10
#     end
#   end
#
module Induction
  class ScenarioBuilder
    Scenario = Data.define(:label, :id, :block)

    attr_reader :scenarios, :clients

    # @yieldparam builder [ScenarioBuilder]
    # @return [ScenarioBuilder]
    def self.define(&block)
      new.tap { |builder| builder.instance_eval(&block) }
    end

    def initialize
      @scenarios = {}
      @clients = []
      @trn_prefixes = []
    end

    # @param label [Symbol] the sceanrio identifier
    # @param id [Integer] the ID encoded into the TRN
    # @yieldparam trn [String]
    # @yieldparam name [String]
    # @yieldparam index [Integer]
    # @return [void]
    # @raise [ArgumentError]
    def scenario(label, id:, &block)
      raise ArgumentError, "Invalid scenario ID: #{id}" unless (1..99).cover?(id) && id.is_a?(Integer)
      raise ArgumentError, "Duplicate scenario label: #{label}" if scenarios.key?(label)
      raise ArgumentError, "Duplicate scenario ID: #{id}" if scenarios.values.any? { |scenario| scenario.id == id }
      raise ArgumentError, "Missing scenario block: #{label}" unless block

      scenarios[label] = Scenario.new(label:, id:, block:)
    end

    # @param name [String] the name of the consumer
    # @param trn_prefix [String, Integer] the client code the consumer's TRNs start with
    # @yieldparam client [ClientBuilder]
    # @return [void]
    # @raise [ArgumentError]
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

  # Seeds scenarios for one API consumer, and creates that consumer's OAuth client.
  class ClientBuilder
    attr_reader :client

    # @param name [String] the name of the consumer
    # @param trn_prefix [String] the client code the consumer's TRNs start with
    # @param scenarios [Hash{Symbol => ScenarioBuilder::Scenario}]
    def initialize(name, trn_prefix:, scenarios:)
      @name = name
      @trn_prefix = trn_prefix
      @scenarios = scenarios
      @seeded_scenarios = []
    end

    # @param grant_type [Symbol] the OAuth grant type the client is allowed to use
    # @return [Api::Oauth::Client] the consumer's OAuth client
    def oauth_client(grant_type: :authorization_code)
      print_seed_info("Seeding induction client '#{@name}'", colour: :green)

      return @client if @client

      @client = FactoryBot.create(
        :api_oauth_client,
        name: @name,
        grant_types: [grant_type]
      )
    end

    # @param count [Integer] how many instances of each scenario to seed
    # @return [void]
    def seed_all(count: 1)
      @scenarios.each_key { |label| seed(label, count:) }
    end

    # @param label [Symbol] the scenario to seed
    # @param count [Integer] how many instances to seed
    # @return [void]
    # @raise [ArgumentError]
    def seed(label, count: 1)
      scenario = @scenarios.fetch(label)

      raise ArgumentError, "Invalid seed count: #{count}" unless count.is_a?(Integer) && (1..1000).cover?(count)
      raise ArgumentError, "Scenario already seeded: #{label}" if @seeded_scenarios.include?(label)

      print_seed_info(
        "Seeding induction scenario '#{label}' *#{count}* #{'time'.pluralize(count)} for #{@name}",
        colour: :yellow
      )

      count.times do |index|
        instance_exec(
          trn: teacher_trn(scenario, index),
          name: teacher_name(scenario, index),
          index:,
          &scenario.block
        )
      end

      @seeded_scenarios << label
    end

  private

    def teacher_trn(scenario, index)
      sprintf("%s%02d%03d", @trn_prefix, scenario.id, index)
    end

    def teacher_name(scenario, index)
      first_name = @name.gsub(/[\s_]/, "-")
      last_name = scenario.label.to_s.tr("_", "-").capitalize

      "#{first_name} #{last_name}-#{index}"
    end
  end
end
