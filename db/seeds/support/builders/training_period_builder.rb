module TeacherHistories
  class TrainingPeriodBuilder
    include TeacherHistories::DateExtractor
    include TeacherHistories::Indentation

    attr_reader :training_period

    def initialize(training_period)
      @training_period = training_period
    end

    def base_indent_level = 8

    def declarations(types)
      milestone_data = training_period
        .schedule
        .milestones
        .each_with_object({}) do |ms, hash|
          hash[ms.declaration_type] = ms.milestone_date
        end

      case types
      when Array
        milestone_data.slice(*types).each do |type, date|
          traits = case
                   when date < 1.year.ago   then :paid
                   when date < 6.months.ago then :eligible
                   when date < 3.months.ago then :payable
                   else                          :no_payment
                   end

          declaration(type, date - Random.rand(60).days, *traits)
        end
      when Hash
        milestone_data.slice(*types.keys).each do |type, date|
          traits = types[type]
          declaration(type, date - Random.rand(60).days, *traits)
        end
      end
    end

    def declaration(declaration_type, declaration_date, *traits, &block)
      declaration = FactoryBot.build(
        :declaration,
        *traits,
        training_period:,
        declaration_type:,
        declaration_date:,
        delivery_partner_when_created: training_period.delivery_partner
      )

      if declaration.save
        print_seed_info("🧾 #{declaration.declaration_type} declaration added (#{declaration.declaration_date.to_date})", indent:)

        Events::Record.record_declaration_created_event!(author:, teacher: training_period.teacher, lead_provider: training_period.lead_provider, declaration:)
      else
        print_seed_info("Invalid #{declaration.declaration_type} declaration #{declaration.declaration_date}", error: true, indent:)
        print_seed_info("Valid milestones:", error: true, indent: indent(2))

        training_period.schedule.milestones.select(:declaration_type, :milestone_date).each do |ms|
          print_seed_info("#{ms.declaration_type}: #{ms.milestone_date}", error: true, indent: indent(4))
        end

        print_seed_info("Error messages: #{declaration.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        DeclarationBuilder.new(declaration).instance_eval(&block)
      end
    end

  private

    def author
      Events::SystemAuthor.new
    end
  end
end
