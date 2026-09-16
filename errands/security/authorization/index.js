const permissions = {
  customer: [
    "errand:create",
    "errand:read:own",
    "message:send"
  ],

  runner: [
    "assignment:read",
    "assignment:accept",
    "location:update",
    "message:send"
  ],

  operations: [
    "dispatch:manage",
    "tracking:monitor",
    "runner:manage"
  ],

  admin: ["*"]
};

export function can(role, permission) {
  const list = permissions[role] || [];

  return (
    list.includes("*") ||
    list.includes(permission)
  );
}
