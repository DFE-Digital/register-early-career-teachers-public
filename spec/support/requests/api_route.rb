APIRoute = Data.define(:verb, :path, :controller) do
  class << self
    def only(*apis, except: [])
      routes = apis.flat_map { for_api(it) }
      routes.reject { it.controller.in?(except) }
    end

    def with_concern(concern, only:) = self.only(*only).select { it.controller.include?(concern) }

    def for_api(api)
      path = api == :oauth ? "/oauth/" : "/api/#{api}/"

      Rails.application.routes.routes.filter_map do |route|
        next unless route.path.spec.to_s.start_with?(path)

        new(
          verb: route.verb.downcase.to_sym,
          # Any value will do: requests fail authentication or body parsing before a path param is used to find a record.
          path: route.format(route.required_parts.index_with { "123456" }),
          controller: "#{route.defaults.fetch(:controller)}_controller".camelize.constantize
        )
      end
    end
  end

  def authenticated?
    controller.include?(API::TokenAuthenticatable) ||
      controller.include?(API::OAuth::TokenAuthenticable) ||
      controller.include?(API::OAuth::ClientAuthenticable)
  end

  def to_s = "#{verb.upcase} #{path}"
end
