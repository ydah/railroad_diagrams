D = Steep::Diagnostic

target :lib do
  signature "sig"
  signature "sig/generated"

  check "lib"
  ignore "lib/railroad_diagrams/svg", "lib/railroad_diagrams/text"

  library "optparse"

  configure_code_diagnostics(D::Ruby.lenient)
end

target :rendering do
  signature "sig"
  signature "sig/generated"

  check "lib/railroad_diagrams/svg"
  check "lib/railroad_diagrams/text"

  configure_code_diagnostics(D::Ruby.default)
end
