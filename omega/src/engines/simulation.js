export const simulate = async (input = {}) => ({
  type: "simulation",
  input,
  status: "complete",
  outcome: "simulated"
})
