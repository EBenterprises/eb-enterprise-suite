#!/usr/bin/env node
import {OMEGA} from "../src/omega.js"

const omega=await OMEGA.boot(process.cwd())
const [command="help",...args]=process.argv.slice(2)

const print=x=>
  console.log(
    typeof x==="string"
      ?x
      :JSON.stringify(x,null,2)
  )

switch(command){
  case"status":
    print(omega.status())
    break

  case"invent":
    print(omega.invent(args.join(" ")||"invent something"))
    break

  case"simulate":
    print(omega.simulate(args.join(" ")))
    break

  case"evolve":
    print(omega.evolve(args.join(" ")))
    break

  case"release":
    print(omega.release())
    break

  case"rollback":
    print(omega.rollback(args[0]))
    break

  case"versions":
    print(omega.versions())
    break

  case"events":
    print(omega.events.recent(100))
    break

  case"command":
    print(omega.command(args.join(" ")))
    break

  case"serve":
    await import("../server.js")
    break

  default:
    print(`
OMEGA®

status
invent <intent>
simulate
evolve
release
rollback <version>
versions
events
command <intent>
serve
`)
}
