"use strict";

const crypto = require("crypto");

const sessions = new Map();

function createSession(subject, role = "customer") {
    if (!subject) {
        throw new Error("Session subject required");
    }

    const token = crypto.randomBytes(32).toString("hex");

    const session = {
        token,
        subject,
        role,
        createdAt: new Date().toISOString(),
        lastSeenAt: new Date().toISOString()
    };

    sessions.set(token, session);

    return session;
}

function getSession(token) {
    if (!token) return null;

    const session = sessions.get(token);

    if (!session) return null;

    session.lastSeenAt = new Date().toISOString();

    return session;
}

function revokeSession(token) {
    return sessions.delete(token);
}

function count() {
    return sessions.size;
}

module.exports = {
    createSession,
    getSession,
    revokeSession,
    count
};
