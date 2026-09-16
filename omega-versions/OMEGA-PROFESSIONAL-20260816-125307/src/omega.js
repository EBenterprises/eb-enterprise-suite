import fs from "node:fs"
import path from "node:path"
import {parseOmega} from "./parser.js"
import {EventFabric} from "./events.js"
import {ConstraintEngine} from "./constraints.js"
import {InventionEngine} from "./invention.js"
import {SimulationEngine} from "./simulation.js"
import {VersionEngine} from "./versions.js"

export class OMEGA{
  static async boot(root=process.cwd()){
    const omega=new OMEGA(root)
    omega.load()
    omega.events.emit("omega.boot",{version:omega.system.version})
    return omega
  }

  constructor(root){
    this.root=root
    this.system=null
    this.events=new EventFabric()
    this.inventions=new InventionEngine(this)
    this.simulator=new SimulationEngine()
    this.versionsEngine=new VersionEngine(root)
    this.constraints=null
    this.last=null
  }

  load(){
    const file=path.join(this.root,".omega","system.omega")

    this.system=parseOmega(
      fs.readFileSync(file,"utf8")
    )

    this.constraints=new ConstraintEngine(this.system)
  }

  status(){
    return {
      name:this.system.name,
      version:this.system.version,
      state:"ONLINE",
      runtime:{
        node:process.version,
        platform:process.platform,
        arch:process.arch,
        pid:process.pid
      },
      capabilities:Object.keys(this.system.intelligence||{}),
      constraints:this.constraints.list(),
      versions:this.versionsEngine.all().length,
      events:this.events.events.length
    }
  }

  invent(intent="maximize useful capability"){
    this.last=this.inventions.generate(intent)

    this.events.emit(
      "invention.generated",
      {
        intent,
        count:this.last.candidates.length,
        best:this.last.best.name
      }
    )

    return this.last
  }

  simulate(intent){
    const invention=this.last||this.invent(intent)

    const result=this.simulator.evaluate(invention)

    this.lastSimulation=result

    this.events.emit(
      "simulation.completed",
      {
        best:result.best.name,
        score:result.best.simulation.score
      }
    )

    return result
  }

  evolve(intent){
    const simulation=this.simulate(intent)

    const version=this.versionsEngine.create(
      simulation,
      this.system.version
    )

    this.events.emit(
      "version.created",
      version
    )

    return version
  }

  release(){
    const result=this.versionsEngine.canary()

    this.events.emit(
      "release.canary",
      result
    )

    return result
  }

  rollback(version){
    const result=this.versionsEngine.rollback(version)

    this.events.emit(
      "release.rollback",
      result
    )

    return result
  }

  versions(){
    return this.versionsEngine.all()
  }

  command(intent){
    const text=String(intent||"").trim()
    const lower=text.toLowerCase()

    this.events.emit(
      "intent.received",
      {intent:text}
    )

    if(
      lower.includes("invent")||
      lower.includes("create")||
      lower.includes("build")
    )
      return this.invent(text)

    if(
      lower.includes("simulate")||
      lower.includes("test")
    )
      return this.simulate(text)

    if(
      lower.includes("improve")||
      lower.includes("evolve")||
      lower.includes("optimize")
    )
      return this.evolve(text)

    if(
      lower.includes("release")||
      lower.includes("deploy")||
      lower.includes("launch")
    )
      return this.release()

    if(lower.includes("rollback"))
      return this.rollback(text.split(/\s+/).at(-1))

    return {
      understood:true,
      intent:text,
      next:[
        "invent",
        "simulate",
        "evolve",
        "release",
        "rollback"
      ]
    }
  }
}
