import { get, list } from "./registry.js"
import { emit } from "./events.js"
import * as state from "./state.js"
import { OmegaError } from "./public-contract.js"

export const execute = async (
  name,
  input = {},
  context = {}
) => {
  const capabilityName = String(name)

  const capability = get(capabilityName)

  if (!capability) {
    throw new OmegaError(
      `Unknown capability: ${capabilityName}`,
      "UNKNOWN_CAPABILITY",
      {
        name: capabilityName
      }
    )
  }

  const started = Date.now()

  await emit(
    "before:execute",
    {
      name: capabilityName,
      input,
      context
    }
  )

  const result = await capability.run(
    input,
    {
      ...context,
      state,
      execute
    }
  )

  const output = {
    capability: capabilityName,
    result,
    duration: Date.now() - started,
    timestamp: new Date().toISOString()
  }

  await emit(
    "after:execute",
    output
  )

  state.set(
    "lastExecution",
    output
  )

  state.save()

  return output
}

export const capabilities = () => list()

export const health = () => ({
  name: "OMEGA",
  status: "operational",
  capabilities: list().length,
  timestamp: new Date().toISOString()
})
