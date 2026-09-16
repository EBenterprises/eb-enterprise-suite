export class ConstraintEngine {
    constructor(system) {
        this.system = system
    }

    list() {
        return Object.entries(
            this.system.constraints || {}
        ).map(([name, type]) => ({
            name,
            type
        }))
    }

    hard() {
        return this.list()
            .filter(x => x.type === "hard")
            .map(x => x.name)
    }

    validate(candidate) {
        const violations = candidate.violations || []

        const hardViolations =
            violations.filter(
                violation => this.hard().includes(violation)
            )

        return {
            valid: hardViolations.length === 0,
            violations,
            hardViolations
        }
    }

    score(candidate) {
        const result = this.validate(candidate)

        if (!result.valid) {
            return 0
        }

        return 1
    }
}
