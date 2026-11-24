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
    attr_reader :client

    def initialize(name, trn_prefix:, scenarios:)
      @name = name
      @trn_prefix = trn_prefix
      @scenarios = scenarios
      @seeded_scenarios = []
    end

    def oauth_client(grant_type: :authorization_code)
      print_seed_info("Seeding induction client '#{@name}'", colour: :green)

      return @client if @client

      @client = FactoryBot.create(
        :api_oauth_client,
        name: @name,
        grant_types: [grant_type]
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
