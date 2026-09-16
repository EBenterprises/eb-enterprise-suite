class Router {
    constructor() {
        this.routes = [];
    }

    register(method, path, handler) {
        this.routes.push({
            method: method.toUpperCase(),
            path,
            handler
        });

        return this;
    }

    match(method, path) {
        return this.routes.find(
            route =>
                route.method === method.toUpperCase() &&
                route.path === path
        );
    }

    list() {
        return [...this.routes];
    }
}

module.exports = Router;
