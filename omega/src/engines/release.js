export const release = async (input = {}) => ({
  type: "release",
  version: input.version ?? "next",
  status: "prepared"
})
