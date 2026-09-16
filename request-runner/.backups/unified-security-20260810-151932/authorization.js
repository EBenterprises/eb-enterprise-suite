"use strict";

const ROLES = Object.freeze([
    "customer",
    "driver",
    "dispatcher",
    "operator",
    "administrator"
]);

const PERMISSIONS = Object.freeze({
    customer: [
        "request:create",
        "request:read:self",
        "order:read:self"
    ],

    driver: [
        "request:read:assigned",
        "request:update:assigned",
        "order:read:assigned"
    ],

    dispatcher: [
        "request:read",
        "request:assign",
        "order:read",
        "order:update"
    ],

    operator: [
        "request:read",
        "order:read",
        "driver:read",
        "operations:read"
    ],

    administrator: ["*"]
});

function isRole(role) {
    return ROLES.includes(role);
}

function can(role, permission) {
    if (!isRole(role)) return false;

    const permissions = PERMISSIONS[role] || [];

    return permissions.includes("*") ||
           permissions.includes(permission);
}

function assertCan(role, permission) {
    if (!can(role, permission)) {
        throw new Error(
            `Authorization denied: ${role} -> ${permission}`
        );
    }

    return true;
}

module.exports = {
    ROLES,
    PERMISSIONS,
    isRole,
    can,
    assertCan
};
