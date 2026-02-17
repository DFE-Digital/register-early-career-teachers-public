module Migrators
  class ChildRecordError < StandardError
    attr_reader :parent

    def initialize(message, parent = nil)
      @parent = parent
      super(message)
    end
  end

  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :worker

    class << self
      def migrate!(args = {})
        new(**args).migrate!
      end

      def queue
        DataMigration.where(model:).update!(queued_at: Time.zone.now)

        number_of_workers.times do |worker|
          MigratorJob.perform_later(migrator: self, worker:)
        end
      end

      def prepare!
        number_of_workers.times do |worker|
          data_migration = DataMigration.create!(model:, worker:)
          FailureManager.purge_failures!(data_migration)
        end
      end

      def runnable?
        DataMigration.incomplete.where(model: dependencies).none? &&
          DataMigration.queued.where(model:).none?
      end

      def record_count
        raise NotImplementedError
      end

      def model
        raise NotImplementedError
      end

      def dependencies
        []
      end

      def number_of_workers
        [1, (record_count / records_per_worker.to_f).ceil].max
      end

      def records_per_worker
        3_000
      end

      def reset!
        raise NotImplementedError
      end

      def migrators
        load_descendants if descendants.empty?
        descendants
      end

      def migrators_in_dependency_order
        graph = migrators.index_by(&:model)

        each_node = ->(&b) { graph.each_key(&b) }
        each_child = ->(model, &b) { graph[model].dependencies.each(&b) }

        TSort.strongly_connected_components(each_node, each_child).flatten.map { |key| graph[key] }
      end

      def find_by_model(model)
        migrators.find { |migrator| migrator.model.eql?(model.to_sym) }
      end

      def load_descendants
        Dir[File.join(__dir__, "*.rb")].each { |f| require f }
      end
    end

  protected

    def migrate(collection, &block)
      DeclarativeUpdates.skip do
        items = collection.order(:id).offset(offset).limit(limit)

        start_migration!(items.count)

        if respond_to?(:preload_caches, true)
          preload_caches
        end

        # As we're using offset/limit, we can't use find_each!
        items.each { |item| process_item(item, &block) }

        finalise_migration!
      end
    end

    def run_once
      yield if worker.zero?
    end

    def failure_manager
      @failure_manager ||= FailureManager.new(data_migration:)
    end

    def data_migration
      @data_migration ||= DataMigration.find_by(model: self.class.model, worker:)
    end

    def cache_manager
      @cache_manager ||= CacheManager.instance
    end

    def find_lead_provider_id!(ecf_id:)
      lead_provider_ids_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProvider")
    end

    def find_active_lead_provider_id!(lead_provider_id:, contract_period_year:)
      active_lead_provider_ids_by_lead_provider_and_contract_period["#{lead_provider_id} #{contract_period_year}"] || raise(ActiveRecord::RecordNotFound, "Couldn't find ActiveLeadProvider")
    end

    def find_school_partnership!(lead_provider_delivery_partnership_id:, school_id:)
      school_partnership = cache_manager.find_school_partnership(lead_provider_delivery_partnership_id:, school_id:)
      raise(ActiveRecord::RecordNotFound, "Couldn't find SchoolPartnership") unless school_partnership

      school_partnership
    end

    def find_teacher_by_trn!(trn)
      teacher = cache_manager.find_teacher_by_trn(trn)
      raise(ActiveRecord::RecordNotFound, "Couldn't find Teacher with TRN: #{trn}") unless teacher

      teacher
    end

    def find_teacher_by_api_ect_training_record_id!(id)
      teacher = cache_manager.find_teacher_by_api_ect_training_record_id(id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find Teacher with api_ect_training_record_id!: #{id}") unless teacher

      teacher
    end

    def find_teacher_by_api_mentor_training_record_id!(id)
      teacher = cache_manager.find_teacher_by_api_mentor_training_record_id(id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find Teacher with api_mentor_training_record_id!: #{id}") unless teacher

      teacher
    end

    def find_statement_by_api_id!(api_id)
      statement = cache_manager.find_statement_by_api_id(api_id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find Statement with API ID: #{api_id}") unless statement

      statement
    end

    def find_lead_provider_delivery_partnership_by_key!(active_lead_provider_id:, delivery_partner_id:)
      lpdp = cache_manager.find_lead_provider_delivery_partnership_by_key(active_lead_provider_id:, delivery_partner_id:)
      raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProviderDeliveryPartnership with active_lead_provider_id #{active_lead_provider_id} and delivery_partner_id #{delivery_partner_id}") unless lpdp

      lpdp
    end

    def find_lead_provider_by_ecf_id!(ecf_id)
      lead_provider = cache_manager.find_lead_provider_by_ecf_id(ecf_id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProvider with ecf_id #{ecf_id}") unless lead_provider

      lead_provider
    end

    def find_delivery_partner_by_api_id!(api_id)
      delivery_partner = cache_manager.find_delivery_partner_by_api_id(api_id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find DeliveryPartner with api_id #{api_id}") unless delivery_partner

      delivery_partner
    end

    def find_contract_period_by_year!(year)
      contract_period = cache_manager.find_contract_period_by_year(year)
      raise(ActiveRecord::RecordNotFound, "Couldn't find ContractPeriod with year #{year}") unless contract_period

      contract_period
    end

    def find_school_by_urn!(urn)
      school = cache_manager.find_school_by_urn(urn)
      raise(ActiveRecord::RecordNotFound, "Couldn't find School with URN #{urn}") unless school

      school
    end

  private

    def process_item(item)
      success = yield(item)
      DataMigration.update_counters(data_migration.id, processed_count: 1, failure_count: success ? 0 : 1)
    rescue StandardError => e
      DataMigration.update_counters(data_migration.id, failure_count: 1, processed_count: 1)
      failure_manager.record_failure(item, e.message)
    end

    def offset
      worker * self.class.records_per_worker
    end

    def limit
      # allow us to select a subset for testing if record_count is huge and we limit it
      [self.class.records_per_worker, self.class.record_count].min
    end

    def start_migration!(total_count)
      # Reset cache stats tracking for this new DataMigration record
      cache_manager.reset_stats_tracking!

      # We reset the processed/failure counts in case this is a retry.
      data_migration.update!(
        started_at: Time.zone.now,
        total_count:,
        processed_count: 0,
        failure_count: 0,
        completed_at: nil
      )
      log_info("Migration started")
    end

    def log_info(message)
      migration_details = data_migration.reload.attributes.slice(
        "model",
        "worker",
        "processed_count",
        "total_count"
      ).symbolize_keys

      Rails.logger.info("#{message}: [#{migration_details}]")
    end

    def finalise_migration!
      data_migration.update!(completed_at: 1.second.from_now, cache_stats: cache_manager.cache_stats)

      log_info("Migration completed")

      return unless DataMigration.incomplete.where(model: self.class.model).none?

      # Queue a follow up migration to migrate any
      # dependent models.
      MigrationJob.set(wait: 10.seconds).perform_later
    end

    def lead_provider_ids_by_ecf_id
      @lead_provider_ids_by_ecf_id ||= ::LeadProvider.pluck(:ecf_id, :id).to_h
    end

    def active_lead_provider_ids_by_lead_provider_and_contract_period
      @active_lead_provider_ids_by_lead_provider_and_contract_period ||= ::ActiveLeadProvider.pluck(:lead_provider_id, :contract_period_year, :id).to_h { |s| ["#{s[0]} #{s[1]}", s[2]] }
    end
  end
end
