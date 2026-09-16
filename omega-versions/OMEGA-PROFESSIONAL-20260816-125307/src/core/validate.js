export const validate = value => {
  const errors = []

  if (value == null)
    errors.push("value is null")

  return {
    valid: errors.length === 0,
    errors
  }
}
