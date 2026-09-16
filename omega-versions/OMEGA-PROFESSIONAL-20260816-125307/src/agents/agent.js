import { run } from "../orchestration/loop.js"
import { adapt } from "../learning/adaptation.js"

export const agent = async (
  goal,
  cycles = 3
) => {
  const result =
    await run(goal, cycles)

  return {
    type: "agent-run",
    goal,
    cycles,
    best: result.best,
    adaptation: adapt(
      result.history
    )
  }
}
