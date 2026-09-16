export const evolve = async (input = {}) => ({
  type: "evolution",
  input,
  generation: Number(input.generation ?? 1) + 1,
  status: "ready"
})
