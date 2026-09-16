export function publish(event) {
  return {
    published: true,
    event,
    timestamp: new Date().toISOString()
  };
}
