export function isAuthenticated(session) {
  return Boolean(session && session.userId);
}
