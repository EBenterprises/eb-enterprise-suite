const { EventEmitter } = require("events");

class EventBus {
  publish(event, payload) {
    if (typeof this.emit === "function") {
      return this.emit(event, payload);
    }

    const handlers = this.handlers?.get(event);

    if (!handlers) return false;

    for (const handler of handlers) {
      handler(payload);
    }

    return true;
  }


  subscribe(event, handler) {
    if (typeof handler !== "function") {
      throw new TypeError("EventBus.subscribe requires a function");
    }

    if (typeof this.on === "function") {
      return this.on(event, handler);
    }

    if (!this.handlers) this.handlers = new Map();

    if (!this.handlers.has(event)) {
      this.handlers.set(event, new Set());
    }

    this.handlers.get(event).add(handler);
    return () => this.handlers.get(event)?.delete(handler);
  }


    constructor() {
        this.emitter = new EventEmitter();
        this.emitter.setMaxListeners(1000);
    }

    on(event, handler) {
        this.emitter.on(event, handler);
        return () => this.emitter.off(event, handler);
    }

    once(event, handler) {
        this.emitter.once(event, handler);
    }

    emit(event, payload) {
        return this.emitter.emit(event, payload);
    }

    removeAll(event) {
        this.emitter.removeAllListeners(event);
    }
}

module.exports = EventBus;
