class Migration::ModelFailuresController < ::AdminController
  layout "full"

  def index
    @model = params[:model]

    if @model.blank?
      redirect_to migration_failures_path and return
    end

    @failures = fetch_failures_for_model
  end

private

  def fetch_failures_for_model
    model = @model.downcase.to_sym

    {
      model_failures: model_grouped_failures(model),
      linked_failures: teacher_grouped_failures(model),
    }
  end

  def teacher_grouped_failures(model)
    failures = if model == :teacher
                 TeacherMigrationFailure.all
               else
                 TeacherMigrationFailure.where(model:)
               end
    failure_group.new(model, failures.count, failures.group(:message).count.sort.to_h)
  end

  def model_grouped_failures(model)
    failures = migration_failures_for_model(model:)
    failure_group.new(model, failures.count, failures.group(:failure_message).count.sort.to_h)
  end

  def generic_grouped_failures
    migrator_models.map do |model|
      failures = migration_failures_for_model(model:)
      failure_group.new(model, failures.count, failures.group(:failure_message).count.sort.to_h)
    end
  end

  def failure_group
    @failure_group ||= Data.define(:model, :failure_count, :failures)
  end

  def migration_failures_for_model(model:)
    MigrationFailure.joins(:data_migration).where(data_migration: { model: })
  end
end
