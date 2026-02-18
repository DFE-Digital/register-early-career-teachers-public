module APISeedData
  class Declarations < Base
    MAX_TEACHERS_WITH_DECLARATIONS = 25

    def plant
      return unless plantable?

      log_plant_info("declarations")

      active_lead_providers.product(teacher_types).each do |active_lead_provider, teacher_type|
        log_seed_info("#{active_lead_provider.lead_provider.name} - #{teacher_type}", indent: 4)

        MAX_TEACHERS_WITH_DECLARATIONS.times do
          school_partnership = find_random_school_partnership(active_lead_provider)
          next unless school_partnership

          training_periods = find_random_training_periods_without_declarations(school_partnership, teacher_type)
          next if training_periods.blank?

          create_declarations!(active_lead_provider, training_periods)
        end
      end
    end

  protected

    def plantable?
      super && Declaration.none?
    end

    def teacher_types
      %i[ect mentor]
    end

    def active_lead_providers
      ActiveLeadProvider.all.to_a
    end

    def create_declarations!(active_lead_provider, training_periods)
      teacher = training_periods.first.teacher
      log_seed_info(::Teachers::Name.new(teacher).full_name, indent: 4)

      training_period = training_periods.sample

      existing_declarations = if training_period.for_ect?
                                teacher.ect_declarations
                              else
                                teacher.mentor_declarations
                              end

      declaration_types(training_period, active_lead_provider).each do |declaration_type|
        schedule = training_period.schedule
        declaration_date = declaration_date(schedule, declaration_type)

        next unless declaration_date.past?

        payment_status = Declaration.payment_statuses.keys.sample
        unless payment_status == :no_payment
          payment_statement = find_random_statement(active_lead_provider)
          next unless payment_statement
        end

        clawback_status = clawback_status(payment_status)
        unless clawback_status == :no_clawback
          clawback_statement = find_random_statement(active_lead_provider, (payment_statement.deadline_date + 1.day)..)
          next unless clawback_statement
        end

        mentorship_period = training_period.mentorship_periods.sample if training_period.for_ect?

        declaration = FactoryBot.build(
          :declaration,
          declaration_type:,
          declaration_date:,
          payment_status:,
          clawback_status:,
          payment_statement:,
          clawback_statement:,
          training_period:,
          mentorship_period:,
          **uplifts(training_period:, declaration_type:)
        )

        next if existing_declarations.billable_or_changeable.where(declaration_type:).exists?

        declaration.save!
        log_declaration_info(declaration)
      end
    end

    def uplifts(training_period:, declaration_type:)
      return {} unless training_period.contract_period.uplift_fees_enabled? && declaration_type == "started"

      { sparsity_uplift: Faker::Boolean.boolean, pupil_premium_uplift: Faker::Boolean.boolean }
    end

    def log_declaration_info(declaration)
      log_seed_info("#{declaration.declaration_type} - #{declaration.overall_status} - #{declaration.declaration_date.to_date}", indent: 6)
    end

    def find_random_statement(active_lead_provider, deadline_date = :ignore)
      ::Statements::Search.new(
        lead_provider_id: active_lead_provider.lead_provider.id,
        contract_period_years: active_lead_provider.contract_period_year,
        fee_type: "output",
        deadline_date:
      )
      .statements
      .sample
    end

    def clawback_status(payment_status)
      return :no_clawback unless payment_status == "paid"

      Declaration.clawback_statuses.keys.sample
    end

    def declaration_types(training_period, active_lead_provider)
      if training_period.for_mentor? && active_lead_provider.contract_period.mentor_funding_enabled?
        return %w[started completed]
      end

      types = Declaration.declaration_types.keys
      types.sample(rand(1..types.size))
    end

    def declaration_date(schedule, declaration_type)
      milestone = schedule.milestones.find_by(declaration_type:)
      # Sometimes the milestone start_date is in the future; we will omit
      # these declarations in the calling method.
      end_date = [milestone&.start_date, 1.day.ago].compact.max

      return Faker::Date.between(from: Date.new(schedule.contract_period.year), to: end_date) unless milestone

      Faker::Date.between(from: milestone.start_date, to: milestone.milestone_date || end_date)
    end

    def find_random_school_partnership(active_lead_provider)
      active_lead_provider.school_partnerships.sample
    end

    def find_random_training_periods_without_declarations(school_partnership, teacher_type)
      teacher_ids = teacher_ids_without_declarations(school_partnership, teacher_type)
      teacher = Teacher.where(id: teacher_ids).order("RANDOM()").first

      return [] unless teacher

      if teacher_type == :ect
        teacher.ect_training_periods.where(school_partnership:)
      else
        teacher.mentor_training_periods.where(school_partnership:)
      end
    end

    def teacher_ids_with_declarations
      Declaration
        .joins(training_period: %i[ect_at_school_period mentor_at_school_period])
        .pluck("ect_at_school_periods.teacher_id", "mentor_at_school_periods.teacher_id")
        .flatten
        .uniq
    end

    def teacher_ids_without_declarations(school_partnership, teacher_type)
      training_periods = school_partnership.training_periods

      teacher_ids = if teacher_type == :ect
                      training_periods
                        .joins(:ect_at_school_period)
                        .where.not(ect_at_school_periods: { teacher_id: teacher_ids_with_declarations })
                        .pluck(ect_at_school_periods: :teacher_id)
                    else
                      training_periods
                        .joins(:mentor_at_school_period)
                        .where.not(mentor_at_school_periods: { teacher_id: teacher_ids_with_declarations })
                        .pluck(mentor_at_school_periods: :teacher_id)
                    end

      teacher_ids.uniq
    end
  end
end
