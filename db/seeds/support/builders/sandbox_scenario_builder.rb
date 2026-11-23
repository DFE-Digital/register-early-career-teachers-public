# Example DSL for induction API sandbox seeding
# Block params for scenario:
# trn - calculated TRN based on client, scenario and index
# name - calculated teacher name based on client, scenario and index
# index - index of this iteration
#
# Induction::ScenarioBuilder.define do
#   scenario :new_ect_provider_led, id: 1 do |trn, name, index|
#     # build seed stuff using TeacherHistories DSL
#     # ...
#   end
#
#   scenario :new_ect_school_led, id: 2 do |trn, name, index|
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
    attr_reader :scenarios, :clients

    def initialize
      @scenarios = {}
      @clients = []
    end

    def self.define(&block)
      builder = new
      builder.instance_eval(&block)
      builder
    end

    def scenario(label, id:, &block)
      raise "Duplicate induction scenario! [#{label}] id: #{id}" if @scenarios.any? { |k, v| label == k || v[:id] == id }

      @scenarios[label] = { id:, block: }
    end

    def client(name, trn_prefix:, &block)
      builder = ClientBuilder.new(name, trn_prefix:, scenarios:)
      builder.instance_eval(&block) if block_given?
      @clients << builder.client
    end
  end

  class ClientBuilder
    attr_reader :client

    def initialize(name, trn_prefix:, scenarios:)
      @name = name
      @trn_prefix = trn_prefix
      @scenarios = scenarios
      @client = nil
    end

    def oauth_client(grant_type: :authorization_code)
      # this will need an authorization going forward I think (or callback URIs if not)
      print_seed_info("Seeding induction client '#{@name}'", colour: :green)
      @client = FactoryBot.create(:api_oauth_client, name: @name, grant_types: [grant_type])
    end

    def seed(label, count:)
      scenario = @scenarios.fetch(label)

      seeder = ScenarioSeeder.new(label:, scenario:, client_name: @name, trn_prefix: @trn_prefix)
      seeder.seed(count:)
    end
  end

  class ScenarioSeeder
    def initialize(label:, scenario:, client_name:, trn_prefix:)
      @label = label
      @scenario = scenario
      @client_name = client_name
      @trn_prefix = trn_prefix
    end

    def seed(count:)
      @scenario.fetch(:id)
      block = @scenario.fetch(:block)

      print_seed_info("Seeding induction scenario '#{@label}' *#{count}* #{'time'.pluralize(count)} for #{@client_name}", colour: :yellow)

      count.times do |idx|
        instance_exec(make_trn(idx), make_name(idx), idx, &block)
      end
    end

  private

    def make_trn(index)
      sprintf("%s%02d%03d", @trn_prefix.to_s.rjust(2, "0"), @scenario.fetch(:id), index)
    end

    def make_name(index)
      # make it friendly enough for turning into an email in TeacherHistories
      firstname = @client_name.gsub(/[\s_]/, "-")
      lastname = @label.to_s.tr("_", "-").capitalize
      "#{firstname} #{lastname}-#{index}"
    end
  end
end
