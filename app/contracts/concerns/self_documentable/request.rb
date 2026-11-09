module SelfDocumentable::Request
  extend ActiveSupport::Concern

  include SelfDocumentable

  included do
    class_attribute :path_params, instance_writer: false, default: {}
  end

  class_methods do
    def path_param(name, from:)
      self.path_params = path_params.merge(name => from)
    end

    def param_key
      name.demodulize.delete_suffix("Request").underscore.to_sym
    end

    def parse(params)
      params.expect(param_key => openapi_fields.keys)
            .merge(path_params.transform_values { params[it] })
            .to_h.symbolize_keys
    end
  end
end
