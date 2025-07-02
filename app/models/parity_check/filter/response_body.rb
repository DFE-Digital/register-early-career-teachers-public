module ParityCheck::Filter
  class ResponseBody
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :response
    attribute :selected_key_paths

    delegate :ecf_body_hash, :rect_body_hash, to: :response

    # Not all response bodies are JSON.
    def filterable?
      filterable_key_hash.any?
    end

    # Sorted key structure of the response bodies, for example:
    #
    # {
    #  key1: {}
    #  key2: {
    #   subkey1: {},
    #   subkey2: {}
    #  }
    # }
    def filterable_key_hash
      rect_key_hash.merge(ecf_key_hash)
    end

    # Checks if a key path has been selected for filtering, for example:
    #
    # [:key, :subkey]
    def selected?(key_path)
      return true if selected_key_paths.nil?

      selected_key_paths.include?(key_path.map(&:to_sym))
    end

    # Sets the selected key paths for filtering as an array of strings
    # for convenience with how forms represent array values. For example:
    #
    # ["key subkey", "another_key"]
    def selected_key_paths=(value)
      super(value.nil? ? value : Array.wrap(value).map { it.to_s.split.map(&:to_sym) })

      verify_selected_key_paths!
    end

    # Applies the selected filters to the response bodies.
    def filtered_response
      return response unless filterable? && !selected_key_paths.nil?

      response.tap do
        it.ecf_body = apply_filter(it.ecf_body_hash).to_json if it.ecf_body.present?
        it.rect_body = apply_filter(it.rect_body_hash).to_json if it.rect_body.present?
      end
    end

  private

    def verify_selected_key_paths!
      return if selected_key_paths.blank?

      selected_key_paths.each do |key_path|
        next if key_path.size == 1

        parent_key_path = key_path[...-1]
        next if parent_key_path.in?(selected_key_paths)

        raise ArgumentError, "Parent key path #{parent_key_path} for key path #{key_path} must also be selected."
      end
    end

    def apply_filter(body, parent_path = [])
      return body unless body.is_a?(Hash)

      body.each_with_object({}) do |(key, value), filtered|
        current_path = parent_path + [key.to_sym]

        next unless selected?(current_path)

        filtered[key] = if value.is_a?(Hash)
                          apply_filter(value, current_path)
                        elsif value.is_a?(Array)
                          value.map { |item| apply_filter(item, current_path) }
                        else
                          value
                        end
      end
    end

    def rect_key_hash
      return {} unless rect_body_hash

      @rect_key_hash ||= nested_key_hash(rect_body_hash)
    end

    def ecf_key_hash
      return {} unless ecf_body_hash

      @ecf_key_hash ||= nested_key_hash(ecf_body_hash)
    end

    def nested_key_hash(hash)
      result = {}

      hash.keys.sort.each do |key|
        value = hash[key]
        result[key] = if value.is_a?(Hash) && value.any?
                        nested_key_hash(value)
                      elsif value.is_a?(Array) && value.any?
                        value.map { nested_key_hash(it) }.reduce(:merge)
                      else
                        {}
                      end
      end

      result
    end
  end
end
