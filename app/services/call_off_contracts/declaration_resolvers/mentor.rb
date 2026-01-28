module CallOffContracts::DeclarationResolvers
  class Mentor
    attr_reader :declarations

    def initialize(declarations:)
      @declarations = declarations
    end

    def resolve_declarations
      declarations.select(&:for_mentor?)
    end
  end
end
