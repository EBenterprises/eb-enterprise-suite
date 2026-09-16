import http from "node:http"
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath }
    from "node:url"

import { OMEGA }
    from "./src/core/omega.js"

const root =
    path.dirname(
        fileURLToPath(import.meta.url)
    )

const omega =
    await OMEGA.boot(root)

const publicDir =
    path.join(
        root,
        "public"
    )

const mime = {
    ".html": "text/html",
    ".js": "text/javascript",
    ".css": "text/css",
    ".json": "application/json"
}

function send(
    response,
    status,
    data,
    type = "application/json"
) {
    response.writeHead(
        status,
        {
            "Content-Type":
                `${type}; charset=utf-8`,
            "Cache-Control":
                "no-store"
        }
    )

    response.end(
        type === "application/json"
            ? JSON.stringify(
                data,
                null,
                2
            )
            : data
    )
}

const server =
    http.createServer(
        async (request, response) => {

            try {

                const url =
                    new URL(
                        request.url,
                        "http://localhost"
                    )

                if (
                    url.pathname ===
                        "/api/command" &&
                    request.method ===
                        "POST"
                ) {

                    let body = ""

                    request.on(
                        "data",
                        chunk =>
                            body += chunk
                    )

                    await new Promise(
                        resolve =>
                            request.on(
                                "end",
                                resolve
                            )
                    )

                    const payload =
                        JSON.parse(
                            body || "{}"
                        )

                    return send(
                        response,
                        200,
                        omega.command(
                            payload.command
                        )
                    )
                }

                const routes = {

                    "/api/status":
                        () =>
                            omega.status(),

                    "/api/system":
                        () =>
                            omega.system,

                    "/api/invent":
                        () =>
                            omega.invent(),

                    "/api/simulate":
                        () =>
                            omega.simulate(),

                    "/api/evolve":
                        () =>
                            omega.evolve(),

                    "/api/release":
                        () =>
                            omega.release(),

                    "/api/versions":
                        () =>
                            omega.versionList(),

                    "/api/events":
                        () =>
                            omega.events
                                .recent(100)
                }

                if (
                    routes[
                        url.pathname
                    ]
                ) {
                    return send(
                        response,
                        200,
                        routes[
                            url.pathname
                        ]()
                    )
                }

                const relative =
                    url.pathname === "/"
                        ? "index.html"
                        : url.pathname
                            .slice(1)

                const target =
                    path.resolve(
                        publicDir,
                        relative
                    )

                if (
                    !target.startsWith(
                        path.resolve(
                            publicDir
                        )
                    )
                ) {
                    return send(
                        response,
                        403,
                        {
                            error:
                                "forbidden"
                        }
                    )
                }

                if (
                    !fs.existsSync(
                        target
                    )
                ) {
                    return send(
                        response,
                        404,
                        {
                            error:
                                "not found"
                        }
                    )
                }

                const ext =
                    path.extname(
                        target
                    )

                send(
                    response,
                    200,
                    fs.readFileSync(
                        target
                    ),
                    mime[ext] ||
                        "application/octet-stream"
                )

            } catch (error) {

                send(
                    response,
                    500,
                    {
                        error:
                            error.message
                    }
                )
            }
        }
    )

const port =
    Number(
        process.env.PORT ||
        8787
    )

server.listen(
    port,
    "0.0.0.0",
    () => {

        console.log("")
        console.log(
            "╔════════════════════════════════════════════╗"
        )
        console.log(
            "║              O M E G A ®                  ║"
        )
        console.log(
            "║        ADAPTIVE APPLICATION ENGINE         ║"
        )
        console.log(
            "╚════════════════════════════════════════════╝"
        )
        console.log("")
        console.log(
            `UI: http://127.0.0.1:${port}`
        )
        console.log("")
    }
)
