"use strict";

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

const REQUEST_TRANSITIONS = {
  pending: ["accepted", "cancelled"],
  accepted: ["assigned", "cancelled"],
  assigned: ["en_route", "cancelled"],
  en_route: ["arrived", "cancelled"],
  arrived: ["picked_up", "cancelled"],
  picked_up: ["completed"],
  completed: [],
  cancelled: []
};

const ORDER_TRANSITIONS = {
  pending: ["confirmed", "assigned", "cancelled"],
  confirmed: ["assigned", "cancelled"],
  assigned: ["en_route", "cancelled"],
  en_route: ["arrived", "cancelled"],
  arrived: ["picked_up", "cancelled"],
  picked_up: ["completed"],
  completed: [],
  cancelled: []
};

function canTransition(graph, from, to) {
  return Array.isArray(graph[from]) && graph[from].includes(to);
}

function requestCanTransition(from, to) {
  return canTransition(REQUEST_TRANSITIONS, from, to);
}

function orderCanTransition(from, to) {
  return canTransition(ORDER_TRANSITIONS, from, to);
}

function assertRequestTransition(from, to) {
  if (!requestCanTransition(from, to)) {
    throw new Error(`Invalid request transition: ${from} -> ${to}`);
  }
  return true;
}

function assertOrderTransition(from, to) {
  if (!orderCanTransition(from, to)) {
    throw new Error(`Invalid order transition: ${from} -> ${to}`);
  }
  return true;
}

module.exports = {
  REQUEST_STATES,
  ORDER_STATES,
  REQUEST_TRANSITIONS,
  ORDER_TRANSITIONS,
  requestCanTransition,
  orderCanTransition,
  assertRequestTransition,
  assertOrderTransition
};
