const policies = new Map([
  ["execution", { enabled:true }],
  ["learning", { enabled:true }],
  ["invention", { enabled:true }],
  ["release", { enabled:true }]
])

export const getPolicy = name =>
  policies.get(name) ?? { enabled:false }

export const setPolicy = (name, value) => {
  policies.set(name, {
    ...getPolicy(name),
    ...value
  })
  return policies.get(name)
}

export const allPolicies = () =>
  Object.fromEntries(policies)
