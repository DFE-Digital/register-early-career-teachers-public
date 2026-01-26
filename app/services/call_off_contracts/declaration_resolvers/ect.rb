module CallOffContracts::DeclarationResolvers
  class ECT
    attr_reader :declarations

    def initialize(declarations:)
      @declarations = declarations
    end

    def resolve_declarations
      declarations.select(&:for_ect?)
    end
  end
end
