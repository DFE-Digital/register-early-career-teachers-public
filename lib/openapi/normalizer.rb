module OpenAPI
  class Normalizer
    def self.normalize(value)
      case value
      when Hash
        value.to_h do |key, child|
          [
            key.to_s,
            normalize(child)
          ]
        end
      when Array
        value.map { normalize(it) }
      when Symbol
        value.to_s
      else
        value
      end
    end
  end
end
