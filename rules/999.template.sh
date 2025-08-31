# shellcheck disable=SC2034,SC2148

ID="template"
DESCRIPTION="Not a real rule - copy this to create a new one"

# Optional: return 1 if the rule does not apply in this environment, 0 otherwise
applies() {
  VERBOSE="$1"
  return 1;
}

# return 0 if the check passes, 1 otherwise
check() {
  VERBOSE="$1"
  return 1;
}

# Optional: return 0 if the rule can be auto-fixed, 1 otherwise
can_fix() {
  VERBOSE="$1"
  return 1;
}

# attempt to fix the issue; return 0 on success, 1 otherwise
fix() {
  VERBOSE="$1"
  return 1;
}