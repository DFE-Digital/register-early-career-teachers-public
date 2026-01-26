module CallOffContracts::DeclarationResolvers
  class All
    attr_reader :declarations

    def initialize(declarations:)
      @declarations = declarations
    end

    def resolve_declarations
      declarations
    end
  end
end
