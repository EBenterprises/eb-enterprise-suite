export const reason = (goal, context = {}) => ({
  goal,
  hypotheses: [
    `Improve ${goal}`,
    `Simplify ${goal}`,
    `Scale ${goal}`,
    `Automate ${goal}`,
    `Measure ${goal}`
  ],
  context
})
