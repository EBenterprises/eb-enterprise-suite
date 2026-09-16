import { execute } from "../core/kernel.js"
import { remember } from "../memory/store.js"

export const run = async (
  goal,
  cycles = 3
) => {
  const history = []

  for (let i = 1; i <= cycles; i++) {
    const result = await execute("invent", {
      goal,
      cycle: i
    })

    const item = {
      cycle: i,
      score: result.result.score,
      result
    }

    history.push(item)

    remember({
      type: "cycle",
      goal,
      cycle: i,
      score: item.score
    })
  }

  const best = history.reduce(
    (a, b) =>
      b.score > a.score ? b : a
  )

  return {
    goal,
    cycles,
    best,
    history
  }
}
