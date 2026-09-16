const blocked = [
  "rm -rf /",
  "mkfs",
  ":(){ :|:& };:",
  "dd if=/dev/zero"
]

export const authorize = command => {
  const value =
    String(command).toLowerCase()

  const match =
    blocked.find(x =>
      value.includes(x)
    )

  return {
    allowed: !match,
    reason: match
      ? "blocked-dangerous-command"
      : "approved"
  }
}
