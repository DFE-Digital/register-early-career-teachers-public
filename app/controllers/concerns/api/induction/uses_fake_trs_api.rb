module API::Induction::UsesFakeTRSAPI
  extend ActiveSupport::Concern

  included do
    around_action :use_fake_trs_api, if: :using_fake_trs_api_permitted?
  end

private

  def using_fake_trs_api_permitted?
    Rails.application.config.fake_trs_api_permitted
  end

  def use_fake_trs_api(&block)
    Current.set(use_fake_trs_api: true, &block)
  end
end
