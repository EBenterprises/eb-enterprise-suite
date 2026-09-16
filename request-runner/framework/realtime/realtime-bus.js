class RealtimeBus {
    constructor(io = null) {
        this.io = io;
    }

    attach(io) {
        this.io = io;
        return this;
    }

    publish(event, payload, room = null) {
        if (!this.io) {
            return false;
        }

        if (room) {
            this.io.to(room).emit(event, payload);
        } else {
            this.io.emit(event, payload);
        }

        return true;
    }
}

module.exports = RealtimeBus;
