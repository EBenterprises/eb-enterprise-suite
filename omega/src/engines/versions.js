import fs from "node:fs"
import path from "node:path"

export class VersionEngine {
    constructor(root) {
        this.root = root
        this.file =
            path.join(
                root,
                "data",
                "versions.json"
            )

        fs.mkdirSync(
            path.dirname(this.file),
            { recursive: true }
        )

        if (!fs.existsSync(this.file)) {
            fs.writeFileSync(
                this.file,
                "[]"
            )
        }
    }

    all() {
        return JSON.parse(
            fs.readFileSync(
                this.file,
                "utf8"
            )
        )
    }

    save(versions) {
        fs.writeFileSync(
            this.file,
            JSON.stringify(
                versions,
                null,
                2
            )
        )
    }

    create(simulation, parent) {
        const versions = this.all()

        const version = {
            id: crypto.randomUUID(),
            version:
                `1.${versions.length + 1}.0`,
            parent,
            state: "candidate",
            score:
                simulation.best
                    .simulation
                    .score,
            architecture:
                simulation.best.strategy,
            created:
                new Date().toISOString(),
            lineage:
                versions
                    .filter(v => v.parent === parent)
                    .map(v => v.version)
        }

        versions.push(version)
        this.save(versions)

        return version
    }

    canary() {
        const versions = this.all()

        const candidate =
            [...versions]
                .reverse()
                .find(
                    version =>
                        version.state ===
                        "candidate"
                )

        if (!candidate) {
            return {
                ok: false,
                reason: "No candidate version exists."
            }
        }

        candidate.state = "canary"
        candidate.traffic = 1
        candidate.released =
            new Date().toISOString()

        this.save(versions)

        return {
            ok: true,
            version: candidate
        }
    }

    rollback(version) {
        const versions = this.all()

        const target =
            versions.find(
                item =>
                    item.version === version
            )

        if (!target) {
            return {
                ok: false,
                reason:
                    `Version ${version} was not found.`
            }
        }

        for (const item of versions) {
            if (item.state === "canary") {
                item.state = "rolled-back"
                item.traffic = 0
            }
        }

        target.state = "canary"
        target.traffic = 1

        this.save(versions)

        return {
            ok: true,
            version: target
        }
    }
}
