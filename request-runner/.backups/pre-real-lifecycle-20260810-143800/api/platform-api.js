const express = require("express");

const store = require("./store");
const domain = require("./domain-service");

function createApi(eventBus, realtime) {
    const router = express.Router();

    function emit(event, payload) {
        if (eventBus) {
            eventBus.publish(event, payload);
        }

        if (realtime) {
            realtime.emit(event, payload);
        }
    }

    function asyncRoute(handler) {
        return async (req, res) => {
            try {
                await handler(req, res);
            } catch (error) {
                console.error(error);

                res.status(400).json({
                    error: error.message
                });
            }
        };
    }

    router.get("/health", (req, res) => {
        res.json({
            status: "healthy",
            service: "EB Platform® API",
            timestamp: new Date().toISOString()
        });
    });

    router.get("/customers", (req, res) => {
        res.json({
            data: store.all("customers")
        });
    });

    router.post(
        "/customers",
        asyncRoute(async (req, res) => {
            const customer = domain.createCustomer(req.body);

            emit("customer.created", customer);

            res.status(201).json({
                data: customer
            });
        })
    );

    router.get("/customers/:id", (req, res) => {
        const customer = store.findById(
            "customers",
            req.params.id
        );

        if (!customer) {
            return res.status(404).json({
                error: "Customer not found"
            });
        }

        res.json({
            data: customer
        });
    });

    router.get("/requests", (req, res) => {
        res.json({
            data: store.all("requests")
        });
    });

    router.post(
        "/requests",
        asyncRoute(async (req, res) => {
            const request = domain.createRequest(req.body);

            emit("request.created", request);

            res.status(201).json({
                data: request
            });
        })
    );

    router.get("/requests/:id", (req, res) => {
        const request = store.findById(
            "requests",
            req.params.id
        );

        if (!request) {
            return res.status(404).json({
                error: "Request not found"
            });
        }

        res.json({
            data: request
        });
    });

    router.post(
        "/requests/:id/accept",
        asyncRoute(async (req, res) => {
            const request = store.findById(
                "requests",
                req.params.id
            );

            if (!request) {
                return res.status(404).json({
                    error: "Request not found"
                });
            }

            const order = domain.createOrderFromRequest(request);

            const updated = store.findById(
                "requests",
                request.id
            );

            emit("request.accepted", updated);
            emit("order.created", order);

            res.status(201).json({
                request: updated,
                order
            });
        })
    );

    router.patch(
        "/requests/:id/status",
        asyncRoute(async (req, res) => {
            const request = domain.updateRequestStatus(
                req.params.id,
                req.body.status
            );

            emit("request.status.changed", request);

            res.json({
                data: request
            });
        })
    );

    router.post(
        "/requests/:id/assign",
        asyncRoute(async (req, res) => {
            const request = domain.assignDriver(
                req.params.id,
                req.body.driverId
            );

            emit("request.assigned", request);

            res.json({
                data: request
            });
        })
    );

    router.get("/orders", (req, res) => {
        res.json({
            data: store.all("orders")
        });
    });

    router.get("/orders/:id", (req, res) => {
        const order = store.findById(
            "orders",
            req.params.id
        );

        if (!order) {
            return res.status(404).json({
                error: "Order not found"
            });
        }

        res.json({
            data: order
        });
    });

    router.patch(
        "/orders/:id/status",
        asyncRoute(async (req, res) => {
            const order = domain.updateOrderStatus(
                req.params.id,
                req.body.status
            );

            emit("order.status.changed", order);

            res.json({
                data: order
            });
        })
    );

    router.get("/drivers", (req, res) => {
        res.json({
            data: store.all("drivers")
        });
    });

    router.post(
        "/drivers",
        asyncRoute(async (req, res) => {
            if (!req.body.name) {
                throw new Error("Driver name is required");
            }

            const driver = store.insert("drivers", {
                id: `drv_${Date.now()}`,
                name: String(req.body.name),
                phone: req.body.phone || null,
                status: "available",
                location: req.body.location || null,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            });

            emit("driver.created", driver);

            res.status(201).json({
                data: driver
            });
        })
    );

    router.get("/stats", (req, res) => {
        res.json({
            customers: store.count("customers"),
            requests: store.count("requests"),
            orders: store.count("orders"),
            drivers: store.count("drivers"),
            timestamp: new Date().toISOString()
        });
    });

    return router;
}

module.exports = createApi;
