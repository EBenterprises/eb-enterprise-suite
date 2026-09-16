#!/usr/bin/env node

import {
  execute,
  capabilities,
  health,
  metrics
} from "../src/core/omega.js"

const [command, ...args] = process.argv.slice(2)

const input = {
  prompt: args.join(" "),
  goal: args.join(" ")
}

const main = async () => {
  if (command === "status") {
    console.log(JSON.stringify(health(), null, 2))
    return
  }

  if (command === "capabilities" || command === "list") {
    console.log(JSON.stringify(capabilities(), null, 2))
    return
  }

  if (command === "metrics") {
    console.log(JSON.stringify(metrics.snapshot(), null, 2))
    return
  }

  if (command === "help") {
    console.log("OMEGA®")
    console.log("")
    console.log("Commands:")
    console.log("  status")
    console.log("  capabilities")
    console.log("  metrics")
    console.log("  invent <goal>")
    console.log("  simulate <target>")
    console.log("  evolve <generation>")
    console.log("  release <version>")
    return
  }

  if (!command) {
    console.log("OMEGA®")
    console.log(
      "status | capabilities | metrics | invent | simulate | evolve | release"
    )
    return
  }

  const result = await execute(command, input)
  console.log(JSON.stringify(result, null, 2))
}

main().catch(error => {
  console.error(`[OMEGA ERROR] ${error.message}`)
  process.exitCode = 1
})
