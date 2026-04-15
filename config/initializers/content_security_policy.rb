Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session[:nonce] ||= SecureRandom.hex }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
