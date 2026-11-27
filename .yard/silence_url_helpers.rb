# Silence UndocumentableError because YARD cannot follow `Rails.application.routes.url_helpers`
#
# Loaded by `.yardopts`
YARD::Handlers::Ruby::MixinHandler.class_eval do
  alias_method :process_mixin_before_url_helpers, :process_mixin

  def process_mixin(mixin)
    return if mixin.source == "Rails.application.routes.url_helpers"

    process_mixin_before_url_helpers(mixin)
  end
  protected :process_mixin
end
