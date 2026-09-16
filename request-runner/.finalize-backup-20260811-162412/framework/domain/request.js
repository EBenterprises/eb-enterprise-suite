const Entity = require("./entity");

class Request extends Entity {
    constructor(data = {}) {
        super(data);

        this.type = data.type || "general";
        this.status = data.status || "pending";
        this.customerId = data.customerId || null;
        this.location = data.location || null;
        this.notes = data.notes || "";
    }

    transition(status) {
        this.status = status;
        return this.touch();
    }
}

module.exports = Request;
