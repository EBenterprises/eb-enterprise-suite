export const evaluate = (value, criteria = {}) => {
  const checks = Object.entries(criteria)
  const passed = checks.filter(([key, expected]) => value?.[key] === expected)
  return {
    score: checks.length ? passed.length / checks.length : 1,
    passed: passed.length,
    total: checks.length,
    valid: passed.length === checks.length
  }
}
