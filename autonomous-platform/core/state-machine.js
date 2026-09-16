"use strict";

const VALID = Object.freeze([
    "received",
    "planning",
    "planned",
    "building",
    "verifying",
    "repairing",
    "branching",
    "testing",
    "deploying",
    "monitoring",
    "completed",
    "blocked",
    "cancelled"
]);

const transitions = {
    received: ["planning", "cancelled"],
    planning: ["planned", "repairing", "blocked"],
    planned: ["building", "cancelled"],
    building: [
        "verifying",
        "repairing",
        "branching",
        "blocked"
    ],
    verifying: [
        "testing",
        "repairing",
        "building",
        "blocked"
    ],
    repairing: [
        "branching",
        "building",
        "verifying",
        "blocked"
    ],
    branching: [
        "building",
        "verifying",
        "blocked"
    ],
    testing: [
        "deploying",
        "repairing",
        "building",
        "blocked"
    ],
    deploying: [
        "monitoring",
        "repairing",
        "blocked"
    ],
    monitoring: [
        "completed",
        "repairing",
        "deploying",
        "blocked"
    ],
    blocked: [
        "planning",
        "repairing",
        "cancelled"
    ],
    completed: [],
    cancelled: []
};

function assertState(state) {
    if (!VALID.includes(state)) {
        throw new Error(
            `Invalid platform state: ${state}`
        );
    }
}

function canTransition(from, to) {
    assertState(from);
    assertState(to);

    return transitions[from].includes(to);
}

function transition(from, to) {
    if (!canTransition(from, to)) {
        throw new Error(
            `Illegal transition: ${from} -> ${to}`
        );
    }

    return to;
}

module.exports = {
    VALID,
    transitions,
    canTransition,
    transition
};
