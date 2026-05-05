class TeacherHistory
  attr_reader :teacher,
              :ect_at_school_periods,
              :mentor_at_school_periods,
              :ecf2_ect_combination_summaries,
              :ecf2_mentor_combination_summaries,
              :ecf2_mentorship_summaries,
              :training_periods,
              :mentorship_periods,
              :migration_mode

  def initialize(teacher_hash:)
    @teacher = teacher_hash.deep_symbolize_keys
  end

  def self.build(teacher:)
    # build the objects
    teacher_data = teacher.serializable_hash
    teacher_data[:ect_at_school_periods] = school_period_data(teacher.ect_at_school_periods)
    teacher_data[:mentor_at_school_periods] = school_period_data(teacher.mentor_at_school_periods)

    new(teacher_hash: teacher_data)
  end

  def to_h
    @teacher
  end

  def self.school_period_data(school_periods)
    school_periods.map do |school_period|
      school_period.serializable_hash(
        only: %i[started_on finished_on working_pattern email],
        include: {
          school: { only: :urn, methods: :name },
          training_periods: {
            only: %i[started_on finished_on training_programme deferred_at deferral_reason withdrawn_at withdrawal_reason],
            include: {
              school_partnership: {
                only: %i[id api_id],
                include: {
                  school: { only: :urn, methods: :name },
                  lead_provider: { only: :name },
                  delivery_partner: { only: :name },
                  contract_period: { only: :year },
                }
              },
              expression_of_interest: {
                include: {
                  lead_provider: { only: :name },
                  contract_period: { only: :year },
                }
              },
              schedule: { only: %i[contract_period_year identifier] },
            }
          },
          mentorship_periods: {
            only: %i[started_on finished_on],
            include: {
              mentor: {
                only: %i[started_on finished_on working_pattern email],
                school: { only: :urn, methods: :name },
              },
              mentee: {
                only: %i[started_on finished_on working_pattern email],
                school: { only: :urn, methods: :name },
              }
            }
          }
        }
      )
    end
  end
end
