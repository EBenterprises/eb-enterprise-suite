import { register } from "../core/registry.js"
import { invent } from "../engines/invention.js"
import { simulate } from "../engines/simulation.js"
import { evolve } from "../engines/evolution.js"
import { release } from "../engines/release.js"

export const bootstrap = () => {
  register("invent", invent, { category: "intelligence" })
  register("simulate", simulate, { category: "analysis" })
  register("evolve", evolve, { category: "evolution" })
  register("release", release, { category: "deployment" })
}
