export class OmegaError extends Error {
  constructor(message, code = "OMEGA_ERROR", details = {}) {
    super(message)
    this.name = "OmegaError"
    this.code = code
    this.details = details
  }
}

export const fail = (message, code, details) => {
  throw new OmegaError(message, code, details)
}
