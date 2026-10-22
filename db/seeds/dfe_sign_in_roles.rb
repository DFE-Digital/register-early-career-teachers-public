def describe_dfe_sign_in_role(dfe_sign_in_role)
  print_seed_info(
    "#{dfe_sign_in_role.code} (#{dfe_sign_in_role.dfe_sign_in_role_id})",
    indent: 2
  )
end

{ school_user: 22_521, appropriate_body_user: 22_291 }.each do |code, dfe_sign_in_role_id|
  dfe_sign_in_role = DfESignInRole.find_or_create_by!(code:, dfe_sign_in_role_id:)
  describe_dfe_sign_in_role(dfe_sign_in_role)
end
