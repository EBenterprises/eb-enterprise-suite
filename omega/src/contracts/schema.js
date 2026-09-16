export const contract = (name, required = []) => ({
  name,
  required,
  validate(value = {}) {
    const missing = required.filter(
      key => value[key] === undefined
    )
    return {
      valid: missing.length === 0,
      missing
    }
  }
})
