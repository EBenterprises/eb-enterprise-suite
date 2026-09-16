import { strategy } from "../planning/strategy.js"
import { check } from "../verification/check.js"
import { track } from "../telemetry/tracker.js"

export const flow = async (
  goal,
  steps = strategy(goal).stages
) => {
  const results = []

  for (const step of steps) {
    const result = {
      step,
      goal,
      status: "complete"
    }

    check(result)
    track({
      type: "flow",
      step,
      goal
    })

    results.push(result)
  }

  return {
    goal,
    status: "complete",
    steps: results
  }
}
