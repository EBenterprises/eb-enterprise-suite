import { plan } from "../intelligence/planner.js"

export const invent = async (input = {}) => ({
  type: "invention",
  goal: input.goal ?? input.prompt ?? String(input),
  plan: plan(input.goal ?? input.prompt ?? String(input))
})
