export const ERRAND_STATUS = Object.freeze({
  REQUESTED: "requested",
  VALIDATING: "validating",
  READY_FOR_MATCHING: "ready_for_matching",
  MATCHING: "matching",
  DISPATCHING: "dispatching",
  ASSIGNED: "assigned",
  COORDINATING: "coordinating",
  IN_PROGRESS: "in_progress",
  ARRIVED: "arrived",
  HANDOFF: "handoff",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
  FAILED: "failed"
});

export function createErrand(input = {}) {
  return {
    id: crypto.randomUUID(),
    status: ERRAND_STATUS.REQUESTED,
    title: input.title || "",
    details: input.details || "",
    pickup: input.pickup || null,
    dropoff: input.dropoff || null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}
