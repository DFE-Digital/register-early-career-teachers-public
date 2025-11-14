class SessionRepository
  def initialize(session:, form_key:)
    @session  = session || {}
    @form_key = form_key.to_s
  end

  def [](key)
    store[key.to_s]
  end

  def []=(key, value)
    store[key.to_s] = value.is_a?(Hash) ? value.deep_stringify_keys : value
  end

  def reset
    @session.delete(@form_key)
  end

  def update(args = {})
    args.each { |k, v| self[k] = v }
    true
  end
  alias_method :update!, :update

private

  def method_missing(name, *args)
    string_name = name.to_s
    if string_name.end_with?('=')
      self[string_name[0..-2]] = args.first
    else
      self[string_name]
    end
  end

  def respond_to_missing?(_, _)
    true
  end

  def store
    @session[@form_key] ||= {}
  end
end
