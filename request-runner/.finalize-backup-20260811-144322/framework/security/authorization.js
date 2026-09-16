class Authorization {
    constructor() {
        this.permissions = new Map();
    }

    grant(role, permission) {
        if (!this.permissions.has(role)) {
            this.permissions.set(role, new Set());
        }

        this.permissions.get(role).add(permission);
    }

    revoke(role, permission) {
        this.permissions.get(role)?.delete(permission);
    }

    allows(role, permission) {
        return Boolean(
            this.permissions.get(role)?.has(permission)
        );
    }
}

module.exports = Authorization;
