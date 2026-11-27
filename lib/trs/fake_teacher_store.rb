module TRS
  class FakeTeacherStore
    BOOLEAN_OPTIONS = %i[has_qts has_itt prohibited_from_teaching has_alerts].freeze
    VALUE_OPTIONS = %i[induction_status error_type].freeze
    TEACHER_OPTIONS = (BOOLEAN_OPTIONS + VALUE_OPTIONS).freeze
    STATUS_TYPES = %w[None RequiredToComplete Exempt InProgress Passed Failed FailedInWales].freeze
    ERROR_TYPES = %i[not_found deactivated merged].freeze

    DEFAULT_OPTIONS = {
      has_qts: true,
      has_itt: true,
      prohibited_from_teaching: false,
      has_alerts: false,
      induction_status: nil,
      error_type: nil,
    }.freeze

    # Built-in TRNs, used as a fallback so existing behaviour works without seeding Redis
    SPECIAL_TRNS = {
      "7000001" => { has_qts: false },
      "7000002" => { error_type: :not_found },
      "7000003" => { prohibited_from_teaching: true },
      "7000004" => { error_type: :deactivated },
      "7000005" => { has_alerts: true },
      "7000006" => {}, # seeded as an early roll out mentor
      "7000007" => { induction_status: "Passed" },
      "7000008" => { induction_status: "Failed" },
      "7000009" => { induction_status: "Exempt" },
      "7000010" => { induction_status: "FailedInWales" },
      "7000011" => { error_type: :merged },
    }.transform_values { |opts| { has_itt: false }.merge(opts) }.freeze

    def initialize(redis: nil)
      @redis = redis
    end

    def exists?(trn)
      # used to determine whether this TRN has been seeded with options
      safely { redis.exists?(options_key(trn)) }
    end

    # Options
    def options_for(trn)
      stored_options = safely { redis.hgetall(options_key(trn)) } || {}

      DEFAULT_OPTIONS
        .merge(SPECIAL_TRNS.fetch(trn.to_s, {}))
        .merge(deserialise(stored_options))
    end

    def set_options(trn, **options)
      validate!(options)
      redis.mapped_hmset(options_key(trn), serialise(options))
    end

    def clear_options(trn)
      redis.del(options_key(trn))
    end

    def clear_all_options
      redis.scan_each(match: "*:options", count: 100).each_slice(500) { |keys| redis.del(*keys) }.count
    end

    # Induction
    def set_induction(trn, status:, modified_at:, start_date: nil, completed_date: nil)
      payload = {
        "status" => status,
        "startDate" => start_date,
        "completedDate" => completed_date,
        "modifiedOn" => modified_at,
      }.transform_values { |v| v.presence || "" }

      redis.mapped_hmset(induction_key(trn), payload)
    end

    def induction_for(trn)
      stored_options = safely { redis.hgetall(induction_key(trn)) }
      stored_options.presence&.transform_values(&:presence)
    end

    def clear(trn)
      redis.del(options_key(trn), induction_key(trn))
    end

  private

    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_CACHE_URL", "redis://localhost:6379"))
    end

    def options_key(trn) = "#{trn}:options"
    def induction_key(trn) = "#{trn}:induction"

    def safely
      yield
    rescue Redis::BaseConnectionError => e
      Rails.logger.warn("TRS::FakeTeacherStore could not reach Redis: #{e.message}")
      nil
    end

    def validate!(options)
      unknown_options = options.keys - TEACHER_OPTIONS
      raise ArgumentError, "Unknown option(s): #{unknown_options.join(', ')}" if unknown_options.any?

      if options[:induction_status] && !STATUS_TYPES.include?(options[:induction_status])
        raise ArgumentError, "induction_status must be one of #{STATUS_TYPES.join(', ')}"
      end

      if options[:error_type] && !ERROR_TYPES.include?(options[:error_type])
        raise ArgumentError, "error_type must be one of #{ERROR_TYPES.join(', ')}"
      end
    end

    def serialise(options)
      options.to_h { |k, v| [k.to_s, v.nil? ? "" : v.to_s] }
    end

    def deserialise(stored_options)
      stored_options.each_with_object({}) do |(k, v), out|
        key = k.to_sym
        next unless TEACHER_OPTIONS.include?(key)

        out[key] = BOOLEAN_OPTIONS.include?(key) ? v == "true" : v.presence
      end
    end
  end
end
