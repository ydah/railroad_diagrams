D = Steep::Diagnostic

target :lib do
  signature "sig"
  signature "sig/generated"

  check "lib"

  library "optparse"

  configure_code_diagnostics(D::Ruby.lenient)
end
