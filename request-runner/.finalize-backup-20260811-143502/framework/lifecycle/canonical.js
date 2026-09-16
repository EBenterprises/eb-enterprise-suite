const REQUEST_STATES = [
    "pending",
    "accepted",
    "assigned",
    "en_route",
    "arrived",
    "picked_up",
    "completed",
    "cancelled"
];

const ORDER_STATES = [
    "pending",
    "confirmed",
    "assigned",
    "en_route",
    "arrived",
    "picked_up",
    "completed",
    "cancelled"
];

const TRANSITIONS = {
    pending: ["accepted", "cancelled"],
    accepted: ["assigned", "cancelled"],
    confirmed: ["assigned", "cancelled"],
    assigned: ["en_route", "cancelled"],
    en_route: ["arrived", "cancelled"],
    arrived: ["picked_up", "cancelled"],
    picked_up: ["completed", "cancelled"],
    completed: [],
    cancelled: []
};

function allowedStates(type) {
    return type === "order"
        ? ORDER_STATES
        : REQUEST_STATES;
}

function canTransition(type, from, to) {
    const states = allowedStates(type);

    if (!states.includes(from) || !states.includes(to)) {
        return false;
    }

    if (from === to) {
        return true;
    }

    return (TRANSITIONS[from] || []).includes(to);
}

function assertTransition(type, from, to) {
    if (!canTransition(type, from, to)) {
        throw new Error(
            `Invalid ${type} lifecycle transition: ${from} -> ${to}`
        );
    }

    return true;
}

module.exports = {
    REQUEST_STATES,
    ORDER_STATES,
    TRANSITIONS,
    allowedStates,
    canTransition,
    assertTransition
};
