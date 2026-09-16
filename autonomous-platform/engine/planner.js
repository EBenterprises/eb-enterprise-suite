"use strict";

const graph =
    require("./work-graph");

function ensureRootObjective(
    objective
) {
    if (!objective ||
        !String(objective).trim()) {
        throw new Error(
            "Objective required"
        );
    }

    const existing =
        graph.list();

    if (existing.length > 0) {
        return existing[0];
    }

    return graph.add({
        title:
            "Complete objective",

        description:
            String(objective),

        priority: 100,

        metadata: {
            kind: "root-objective"
        }
    });
}

function expand(task) {
    if (!task) {
        return [];
    }

    /*
     * The planner deliberately does not
     * assume a fixed number of phases.
     *
     * A later LLM planner can replace this
     * deterministic expansion without
     * changing the work-graph contract.
     */

    const existing =
        graph.list();

    const children =
        existing.filter(
            candidate =>
                candidate.metadata &&
                candidate.metadata.parentId ===
                    task.id
        );

    if (children.length) {
        return children;
    }

    const definitions = [
        {
            title: "Discover requirements",
            priority: 95
        },
        {
            title: "Inspect existing implementation",
            priority: 90
        },
        {
            title: "Implement required changes",
            priority: 80
        },
        {
            title: "Run automated tests",
            priority: 70
        },
        {
            title: "Verify acceptance criteria",
            priority: 60
        }
    ];

    return definitions.map(
        (definition, index) =>
            graph.add({
                title:
                    definition.title,

                description:
                    `${definition.title} for: ${task.description}`,

                priority:
                    definition.priority,

                dependsOn:
                    index === 0
                        ? []
                        : [
                            children[index - 1]?.id
                        ].filter(Boolean),

                metadata: {
                    parentId: task.id,
                    generated: true
                }
            })
    );
}

module.exports = {
    ensureRootObjective,
    expand
};
