module StoreDataPreload
  extend ActiveSupport::Concern

  private

  # Sync attributes from the store object to the current wizard step
  def preload_params_from_store(wizard, store)
    return unless wizard&.current_step && store && wizard.permitted_params

    wizard.permitted_params.each do |param|
      next unless should_preload_param?(wizard.current_step, store, param)

      wizard.current_step.public_send("#{param}=", store.public_send(param))
    end
  end

  # Determines if a parameter should be preloaded
  def should_preload_param?(current_step, ect, param)
    current_step.respond_to?(param) && ect.public_send(param).present?
  end
end
