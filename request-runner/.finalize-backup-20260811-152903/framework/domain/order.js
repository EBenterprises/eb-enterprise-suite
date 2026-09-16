const Entity = require("./entity");

class Order extends Entity {
    constructor(data = {}) {
        super(data);

        this.requestId = data.requestId || null;
        this.customerId = data.customerId || null;
        this.status = data.status || "created";
        this.total = Number(data.total || 0);
        this.currency = data.currency || "CAD";
    }

    transition(status) {
        this.status = status;
        return this.touch();
    }
}

module.exports = Order;
