mix deps.get &&
  mix compile --warnings-as-errors &&
  mix format &&
  mix test --slowest 2 &&
  mix dialyzer &&
  mix credo --strict &&
  echo "passed" || echo "failed"
