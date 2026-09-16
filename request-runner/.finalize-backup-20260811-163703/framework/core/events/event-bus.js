const { EventEmitter } = require("events");

class EventBus {
    constructor() {
        this.emitter = new EventEmitter();
        this.emitter.setMaxListeners(1000);
    }

    on(event, handler) {
        if (typeof handler !== "function") {
            throw new TypeError("EventBus.on requires a function");
        }

        this.emitter.on(event, handler);

        return () => {
            this.emitter.off(event, handler);
        };
    }

    subscribe(event, handler) {
        return this.on(event, handler);
    }

    once(event, handler) {
        if (typeof handler !== "function") {
            throw new TypeError("EventBus.once requires a function");
        }

        this.emitter.once(event, handler);
    }

    emit(event, payload) {
        return this.emitter.emit(event, payload);
    }

    publish(event, payload) {
        return this.emit(event, payload);
    }

    off(event, handler) {
        return this.emitter.off(event, handler);
    }

    removeAll(event) {
        this.emitter.removeAllListeners(event);
    }

    listenerCount(event) {
        return this.emitter.listenerCount(event);
    }
}

module.exports = EventBus;
