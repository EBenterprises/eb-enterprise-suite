export const check = value => {
  const errors = []

  if (value === undefined)
    errors.push("undefined")

  if (value === null)
    errors.push("null")

  return {
    valid: errors.length === 0,
    errors
  }
}
