class Events::Metadata
  include Enumerable

  def initialize(attributes = {})
    @attributes = attributes
  end

  # Dynamic attribute access
  def method_missing(method_name, *args, &block)
    if args.empty? && !block_given?
      @attributes[method_name]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @attributes.key?(method_name) || super
  end

  # Make it behave like a hash
  delegate :[], to: :to_hash

  def each(&block)
    to_hash.each(&block)
  end

  def to_hash
    @attributes.compact
  end
end
