class ApplicationComponent < ViewComponent::Base
  include GovukVisuallyHiddenHelper
  include GovukLinkHelper
  include GovukComponentsHelper
  include GovukListHelper
  include ::NumberHelper
end
