const $ =
    selector =>
        document.querySelector(selector)

const $$ =
    selector =>
        [...document.querySelectorAll(selector)]

async function api(
    endpoint,
    options
){
    const response =
        await fetch(
            endpoint,
            options
        )

    return response.json()
}

function show(view){

    $$(".view").forEach(
        element =>
            element.classList.toggle(
                "active",
                element.id === view
            )
    )

    const titles = {
        home:"Command Center",
        invent:"Invention Lab",
        evolve:"Evolution Lab",
        system:"System",
        terminal:"Terminal"
    }

    $("#title").textContent =
        titles[view]

    if(view === "invent")
        loadInvent()

    if(view === "evolve")
        loadVersions()

    if(view === "system")
        loadSystem()
}

$$("aside button").forEach(
    button => {
        button.onclick = () =>
            show(
                button.dataset.view
            )
    }
)

async function status(){

    const result =
        await api(
            "/api/status"
        )

    $("#version").textContent =
        "v" + result.version

    const cards = [
        ["Runtime",result.state],
        ["Constraints",
            result.constraints.length],
        ["Versions",
            result.versions],
        ["Events",
            result.events]
    ]

    $("#stats").innerHTML =
        cards.map(
            card => `
                <div class="card">
                    <span class="muted">
                        ${card[0]}
                    </span>
                    <strong>
                        ${card[1]}
                    </strong>
                </div>
            `
        ).join("")

    const events =
        await api(
            "/api/events"
        )

    $("#events").innerHTML =
        events.slice(0,10).map(
            event => `
                <div class="event">
                    <span>
                        ${event.type}
                    </span>
                    <span class="muted">
                        ${new Date(
                            event.timestamp
                        ).toLocaleTimeString()}
                    </span>
                </div>
            `
        ).join("")
}

async function command(text){

    text =
        String(text || "").trim()

    if(!text)
        return

    const result =
        await api(
            "/api/command",
            {
                method:"POST",
                headers:{
                    "Content-Type":
                        "application/json"
                },
                body:JSON.stringify({
                    command:text
                })
            }
        )

    $("#terminalOutput")
        .insertAdjacentHTML(
            "beforeend",
            `
            <pre>
ω&gt; ${text}
${JSON.stringify(
    result,
    null,
    2
)}
            </pre>
            `
        )

    await status()
}

$("#run").onclick =
    () =>
        command(
            $("#intent").value
        )

$("#intent").onkeydown =
    event => {
        if(event.key === "Enter"){
            command(
                $("#intent").value
            )
        }
    }

$$("[data-command]").forEach(
    button => {
        button.onclick =
            () =>
                command(
                    button.dataset.command
                )
    }
)

$("#terminalInput").onkeydown =
    event => {

        if(event.key === "Enter"){

            command(
                event.target.value
            )

            event.target.value = ""
        }
    }

async function loadInvent(){

    const result =
        await api(
            "/api/invent"
        )

    $("#inventions").innerHTML =
        result.candidates.map(
            candidate => `
                <div class="candidate">

                    <span class="score">
                        ${Math.round(
                            candidate.novelty *
                            100
                        )}% novelty
                    </span>

                    <strong>
                        ${candidate.name}
                    </strong>

                    <div class="muted">
                        ${candidate.strategy}
                    </div>

                    <div class="bar">
                        <i style="
                            width:${
                                candidate.resilience *
                                100
                            }%
                        "></i>
                    </div>

                </div>
            `
        ).join("")
}

async function loadVersions(){

    const versions =
        await api(
            "/api/versions"
        )

    $("#versions").innerHTML =
        versions.length
            ? versions
                .slice()
                .reverse()
                .map(
                    version => `
                        <div class="version">

                            <span class="score">
                                ${version.state}
                            </span>

                            <strong>
                                OMEGA®
                                ${version.version}
                            </strong>

                            <div class="muted">
                                score
                                ${Math.round(
                                    version.score *
                                    100
                                )}%
                                ·
                                ${version.architecture}
                            </div>

                        </div>
                    `
                ).join("")
            : `
                <p class="muted">
                    No versions yet.
                </p>
            `
}

async function loadSystem(){

    $("#system").textContent =
        JSON.stringify(
            await api(
                "/api/system"
            ),
            null,
            2
        )
}

status()

setInterval(
    status,
    4000
)
