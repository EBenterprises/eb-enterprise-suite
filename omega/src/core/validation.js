import { fail } from "./errors.js"

export const required = (value, name) => {
  if (
    value === undefined ||
    value === null ||
    String(value).trim() === ""
  ) {
    fail(
      `${name} is required`,
      "INVALID_INPUT",
      { field: name }
    )
  }

  return value
}

export const object = (value, name = "value") => {
  if (
    value === null ||
    typeof value !== "object" ||
    Array.isArray(value)
  ) {
    fail(
      `${name} must be an object`,
      "INVALID_OBJECT",
      { field: name }
    )
  }

  return value
}
