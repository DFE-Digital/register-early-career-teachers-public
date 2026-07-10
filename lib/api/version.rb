class API::Version
  class << self
    def exists?(version)
      version.to_sym.in?(all)
    end

    def all
      %i[v3 v4]
    end
  end
end
