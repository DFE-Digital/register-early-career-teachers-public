module CallOffContracts::DeclarationResolvers
  class Factory
    def self.create_resolver(assignment:)
      declarations = assignment.statement.declarations
      type = assignment.declaration_resolver_type.to_sym

      case type
      when :all
        All.new(declarations:)
      when :ect
        ECT.new(declarations:)
      when :mentor
        Mentor.new(declarations:)
      else
        raise "Unknown declarations resolver type: #{type}"
      end
    end
  end
end
