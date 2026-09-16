export const plan = (goal, context = {}) => ({
  goal,
  context,
  steps: [
    { type: "observe", goal },
    { type: "analyze", goal },
    { type: "generate", goal },
    { type: "evaluate", goal },
    { type: "optimize", goal }
  ]
})
