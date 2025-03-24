Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session[:nonce] ||= SecureRandom.hex }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
