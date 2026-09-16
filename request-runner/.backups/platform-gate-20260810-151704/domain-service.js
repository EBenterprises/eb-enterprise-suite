const crypto = require("crypto");

const store = require("./store");

const {
    assertRequestTransition,
    assertOrderTransition
} = require("../framework/lifecycle/canonical-lifecycle");

function id(prefix) {
    return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

function now() {
    return new Date().toISOString();
}

function createCustomer(input = {}) {
    if (!input.name || !String(input.name).trim()) {
        throw new Error("Customer name is required");
    }

    const customer = {
        id: id("cus"),
        name: String(input.name).trim(),
        phone: input.phone ? String(input.phone).trim() : null,
        email: input.email ? String(input.email).trim() : null,
        status: "active",
        createdAt: now(),
        updatedAt: now()
    };

    return store.insert("customers", customer);
}

function createRequest(input = {}) {
    if (!input.customerId) {
        throw new Error("customerId is required");
    }

    const customer = store.findById("customers", input.customerId);

    if (!customer) {
        throw new Error("Customer not found");
    }

    const request = {
        id: id("req"),
        customerId: input.customerId,
        pickup: input.pickup || null,
        destination: input.destination || null,
        notes: input.notes || "",
        status: "pending",
        assignedDriverId: null,
        orderId: null,
        createdAt: now(),
        updatedAt: now()
    };

    return store.insert("requests", request);
}

function createOrderFromRequest(request) {
    if (!request) {
        throw new Error("Request not found");
    }

    if (request.orderId) {
        return store.findById("orders", request.orderId);
    }

    const order = {
        id: id("ord"),
        requestId: request.id,
        customerId: request.customerId,
        status: "pending",
        driverId: null,
        createdAt: now(),
        updatedAt: now()
    };

    const created = store.insert("orders", order);

    store.update("requests", request.id, {
        orderId: created.id,
        status: "accepted"
    });

    return created;
}

function updateRequestStatus(requestId, status) {
    const allowed = [
        "pending",
        "accepted",
        "assigned",
        "en_route",
        "arrived",
        "picked_up",
        "completed",
        "cancelled"
    ];

    if (!allowed.includes(status)) {
        throw new Error(`Invalid request status: ${status}`);
    }

    const request = store.findById("requests", requestId);

    if (!request) {
        throw new Error("Request not found");
    }

    assertRequestTransition(request.status, status);

    const current = request.status;
    lifecycle.assertRequestTransition(current, status);

    lifecycle.assertRequestTransition(request.status, status);

    return store.update("requests", requestId, {
        status
    });
}

function updateOrderStatus(orderId, status) {
    const allowed = [
        "pending",
        "confirmed",
        "assigned",
        "en_route",
        "arrived",
        "picked_up",
        "completed",
        "cancelled"
    ];

    if (!allowed.includes(status)) {
        throw new Error(`Invalid order status: ${status}`);
    }

    const order = store.findById("orders", orderId);

    if (!order) {
        throw new Error("Order not found");
    }

    assertOrderTransition(order.status, status);

    const current = order.status;
    lifecycle.assertOrderTransition(current, status);

    lifecycle.assertOrderTransition(order.status, status);

    return store.update("orders", orderId, {
        status
    });
}

function assignDriver(requestId, driverId) {
    const request = store.findById("requests", requestId);

    if (!request) {
        throw new Error("Request not found");
    }

    const driver = store.findById("drivers", driverId);

    if (!driver) {
        throw new Error("Driver not found");
    }

    assertRequestTransition(request.status, "assigned");

    const updated = store.update("requests", requestId, {
        assignedDriverId: driverId,
        status: "assigned"
    });

    if (request.orderId) {
        store.update("orders", request.orderId, {
            driverId,
            status: "assigned"
        });
    }

    return updated;
}

module.exports = {
    createCustomer,
    createRequest,
    createOrderFromRequest,
    updateRequestStatus,
    updateOrderStatus,
    assignDriver
};
