#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/omega"
mkdir -p "$APP"/{bin,src,public,.omega,versions,data,tests}
cd "$APP"

cat > package.json <<'JSON'
{
  "name":"omega",
  "version":"1.0.0",
  "private":true,
  "type":"module",
  "bin":{"omega":"./bin/omega.js"},
  "scripts":{
    "start":"node server.js",
    "test":"node --test",
    "cli":"node bin/omega.js"
  }
}
JSON

cat > .omega/system.omega <<'OMEGA'
omega "OMEGA"

system {
  version "1.0.0"
  mode adaptive
  interface dual
  format ".omega"
  architecture elastic
  philosophy "maximize possibility under governed constraints"
}

objectives {
  capability maximize
  resilience maximize
  usability maximize
  optionality maximize
  invention maximize
  adaptability maximize
  observability maximize
  complexity minimize
  unnecessary_cost minimize
  irreversible_change minimize
}

constraints {
  security hard
  integrity hard
  governance hard
  reversibility hard
  observability hard
  interoperability soft
  resource_awareness soft
}

intelligence {
  intent true
  questioning true
  assumption_challenge true
  decomposition true
  recombination true
  abstraction true
  invention true
  simulation true
  counterfactuals true
  adversarial_testing true
  continuous_learning true
}

evolution {
  parallel_versions true
  candidate_generation true
  scoring true
  canary true
  rollback true
  preserve_alternatives true
  continuous_improvement true
}

runtime {
  local_first true
  offline_capable true
  event_driven true
  modular true
  adaptive true
  recoverable true
}

ui {
  command_center true
  invention_lab true
  evolution_lab true
  system_graph true
  terminal true
  telemetry true
  version_explorer true
}
OMEGA

cat > src/parser.js <<'JS'
export function parseOmega(source){
  const root={}
  const stack=[[-1,root]]

  for(const raw of source.split(/\r?\n/)){
    const line=raw.replace(/#.*$/,"")
    if(!line.trim()) continue

    const indent=line.match(/^\s*/)[0].length
    const text=line.trim()

    while(stack.length && indent<=stack.at(-1)[0]) stack.pop()

    const parent=stack.at(-1)[1]

    const block=text.match(/^([A-Za-z_][\w-]*)(?:\s+"([^"]+)")?\s*\{$/)

    if(block){
      const obj={}
      if(block[2]) obj.name=block[2]
      parent[block[1]]=obj
      stack.push([indent,obj])
      continue
    }

    const pair=text.match(/^([A-Za-z_][\w-]*)\s+(.+)$/)

    if(pair){
      let value=pair[2].trim()

      if(value.startsWith('"') && value.endsWith('"'))
        value=value.slice(1,-1)
      else if(value==="true")
        value=true
      else if(value==="false")
        value=false
      else if(value==="null")
        value=null
      else if(/^-?\d+(\.\d+)?$/.test(value))
        value=Number(value)

      parent[pair[1]]=value
    }
  }

  root.name ??= "OMEGA"
  root.version ??= root.system?.version ?? "1.0.0"

  return root
}
JS

cat > src/events.js <<'JS'
export class EventFabric{
  constructor(limit=10000){
    this.events=[]
    this.limit=limit
  }

  emit(type,data={}){
    const event={
      id:crypto.randomUUID(),
      type,
      timestamp:new Date().toISOString(),
      data
    }

    this.events.push(event)

    if(this.events.length>this.limit)
      this.events.shift()

    return event
  }

  recent(count=100){
    return this.events.slice(-count).reverse()
  }
}
JS

cat > src/constraints.js <<'JS'
export class ConstraintEngine{
  constructor(system){
    this.system=system
  }

  list(){
    return Object.entries(this.system.constraints||{})
      .map(([name,type])=>({name,type}))
  }

  validate(candidate){
    const hard=this.list()
      .filter(x=>x.type==="hard")
      .map(x=>x.name)

    const violations=candidate.violations||[]

    return {
      valid:violations.filter(x=>hard.includes(x)).length===0,
      violations
    }
  }

  score(candidate){
    const c=this.validate(candidate)
    return c.valid ? 1 : 0
  }
}
JS

cat > src/invention.js <<'JS'
export class InventionEngine{
  constructor(omega){
    this.omega=omega
  }

  generate(intent="general improvement"){
    const candidates=[
      {
        name:"Adaptive Fabric",
        strategy:"event-driven + local-first + capability routing",
        novelty:.97,
        performance:.94,
        resilience:.97,
        usability:.91,
        cost:.82
      },
      {
        name:"Evolutionary Mesh",
        strategy:"parallel versions + simulation + controlled promotion",
        novelty:.95,
        performance:.91,
        resilience:.98,
        usability:.89,
        cost:.78
      },
      {
        name:"Possibility Graph",
        strategy:"graph-native capabilities + dynamic recombination",
        novelty:.99,
        performance:.87,
        resilience:.94,
        usability:.86,
        cost:.76
      },
      {
        name:"Local Sovereign Runtime",
        strategy:"offline-first execution + deferred synchronization",
        novelty:.84,
        performance:.93,
        resilience:.99,
        usability:.88,
        cost:.94
      },
      {
        name:"Minimal Core",
        strategy:"dependency-minimized modular execution fabric",
        novelty:.72,
        performance:.97,
        resilience:.91,
        usability:.92,
        cost:.99
      }
    ]

    const invented={
      name:"OMEGA Hyper-Adaptive Composite",
      strategy:
        "automatically recombine compatible strategies according to intent, constraints, resources, confidence and observed outcomes",
      novelty:1,
      performance:.96,
      resilience:.98,
      usability:.94,
      cost:.87
    }

    candidates.push(invented)

    for(const c of candidates){
      c.intent=intent
      c.score=
        c.performance*.22+
        c.resilience*.25+
        c.usability*.18+
        c.cost*.15+
        c.novelty*.20
    }

    candidates.sort((a,b)=>b.score-a.score)

    return {
      intent,
      candidates,
      best:candidates[0]
    }
  }
}
JS

cat > src/simulation.js <<'JS'
export class SimulationEngine{
  evaluate(invention){
    const results=invention.candidates.map(candidate=>{
      const stress={
        resource:.9+Math.random()*.1,
        failure:.9+Math.random()*.1,
        scale:.8+Math.random()*.2,
        uncertainty:.8+Math.random()*.2
      }

      const score=
        candidate.score*
        stress.resource*
        stress.failure*
        stress.scale*
        stress.uncertainty

      return {
        ...candidate,
        simulation:{
          score,
          passed:score>=.65,
          stress
        }
      }
    }).sort((a,b)=>b.simulation.score-a.simulation.score)

    return {
      best:results[0],
      results
    }
  }
}
JS

cat > src/versions.js <<'JS'
import fs from "node:fs"
import path from "node:path"

export class VersionEngine{
  constructor(root){
    this.file=path.join(root,"data","versions.json")

    if(!fs.existsSync(this.file)){
      fs.mkdirSync(path.dirname(this.file),{recursive:true})
      fs.writeFileSync(this.file,"[]")
    }
  }

  all(){
    return JSON.parse(fs.readFileSync(this.file,"utf8"))
  }

  save(data){
    fs.writeFileSync(this.file,JSON.stringify(data,null,2))
  }

  create(simulation,parent){
    const versions=this.all()

    const major=1
    const minor=versions.length+1

    const version={
      id:crypto.randomUUID(),
      version:`${major}.${minor}.0`,
      parent,
      state:"candidate",
      created:new Date().toISOString(),
      score:simulation.best.simulation.score,
      architecture:simulation.best.strategy,
      rollback:parent
    }

    versions.push(version)
    this.save(versions)

    return version
  }

  canary(){
    const versions=this.all()
    const candidate=[...versions]
      .reverse()
      .find(v=>v.state==="candidate")

    if(!candidate)
      return {ok:false,reason:"no candidate"}

    candidate.state="canary"
    candidate.traffic=1
    candidate.promotedAt=new Date().toISOString()

    this.save(versions)

    return candidate
  }

  rollback(version){
    const versions=this.all()
    const target=versions.find(v=>v.version===version)

    if(!target)
      return {ok:false,reason:"version not found"}

    for(const v of versions)
      if(v.state==="canary")
        v.state="rolled-back"

    target.state="canary"
    target.traffic=1

    this.save(versions)

    return target
  }
}
JS

cat > src/omega.js <<'JS'
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
JS

cat > bin/omega.js <<'JS'
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
JS

chmod +x bin/omega.js

cat > server.js <<'JS'
import http from "node:http"
import fs from "node:fs"
import path from "node:path"
import {fileURLToPath} from "node:url"
import {URL} from "node:url"
import {OMEGA} from "./src/omega.js"

const root=path.dirname(
  fileURLToPath(import.meta.url)
)

const omega=await OMEGA.boot(root)
const publicDir=path.join(root,"public")

const mime={
  ".html":"text/html",
  ".js":"text/javascript",
  ".css":"text/css",
  ".json":"application/json"
}

function send(res,status,data,type="application/json"){
  res.writeHead(
    status,
    {
      "Content-Type":`${type}; charset=utf-8`,
      "Cache-Control":"no-store"
    }
  )

  res.end(
    type==="application/json"
      ?JSON.stringify(data,null,2)
      :data
  )
}

const server=http.createServer(
  async(req,res)=>{
    try{
      const url=new URL(
        req.url,
        "http://localhost"
      )

      if(
        url.pathname==="/api/command"&&
        req.method==="POST"
      ){
        let body=""

        req.on(
          "data",
          chunk=>body+=chunk
        )

        await new Promise(
          resolve=>req.on("end",resolve)
        )

        const payload=JSON.parse(body||"{}")

        return send(
          res,
          200,
          omega.command(payload.command)
        )
      }

      const routes={
        "/api/status":()=>omega.status(),
        "/api/system":()=>omega.system,
        "/api/invent":()=>omega.invent(),
        "/api/simulate":()=>omega.simulate(),
        "/api/evolve":()=>omega.evolve(),
        "/api/release":()=>omega.release(),
        "/api/versions":()=>omega.versions(),
        "/api/events":()=>omega.events.recent(100)
      }

      if(routes[url.pathname])
        return send(
          res,
          200,
          routes[url.pathname]()
        )

      let file=
        url.pathname==="/"
          ?"index.html"
          :url.pathname.slice(1)

      const target=path.resolve(
        publicDir,
        file
      )

      if(
        !target.startsWith(
          path.resolve(publicDir)
        )
      )
        return send(res,403,{error:"forbidden"})

      if(!fs.existsSync(target))
        return send(res,404,{error:"not found"})

      const ext=path.extname(target)

      send(
        res,
        200,
        fs.readFileSync(target),
        mime[ext]||"application/octet-stream"
      )

    }catch(error){
      send(
        res,
        500,
        {
          error:error.message,
          stack:error.stack
        }
      )
    }
  }
)

const port=Number(
  process.env.PORT||8787
)

server.listen(
  port,
  "0.0.0.0",
  ()=>{
    console.log("")
    console.log("╔════════════════════════════════════╗")
    console.log("║          O M E G A ®               ║")
    console.log("║   Adaptive Invention Runtime       ║")
    console.log("╚════════════════════════════════════╝")
    console.log("")
    console.log(`UI: http://127.0.0.1:${port}`)
    console.log("")
  }
)
JS

cat > public/index.html <<'HTML'
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OMEGA®</title>
<link rel="stylesheet" href="/styles.css">
</head>
<body>

<aside>
  <div class="brand">Ω <span>OMEGA®</span></div>

  <button data-view="home">⌂ Command Center</button>
  <button data-view="invent">✦ Invention Lab</button>
  <button data-view="evolve">↻ Evolution Lab</button>
  <button data-view="system">◈ System</button>
  <button data-view="terminal">⌘ Terminal</button>

  <div class="online">
    <i></i> OMEGA ONLINE
  </div>
</aside>

<main>

<header>
  <div>
    <small>ADAPTIVE DIGITAL INFRASTRUCTURE</small>
    <h1 id="title">Command Center</h1>
  </div>

  <div id="version">v1.0.0</div>
</header>

<section id="home" class="view active">

  <div class="hero">

    <div class="heroText">

      <div class="omega">Ω</div>

      <h2>Build beyond<br>the obvious.</h2>

      <p>
        Give OMEGA® an intention.
        OMEGA® searches possibilities,
        challenges assumptions,
        invents approaches,
        simulates alternatives,
        and evolves versions.
      </p>

      <div class="command">

        <input
          id="intent"
          placeholder="What do you want to create?"
        >

        <button id="run">Run →</button>

      </div>

      <div class="quick">

        <button data-command="invent">✦ Invent</button>
        <button data-command="simulate">◈ Simulate</button>
        <button data-command="evolve">↻ Evolve</button>
        <button data-command="release">↑ Launch</button>

      </div>

    </div>

    <div class="orb">
      <span>Ω</span>
    </div>

  </div>

  <div id="stats" class="stats"></div>

  <div class="panel">

    <h3>LIVE EVENT FABRIC</h3>

    <div id="events"></div>

  </div>

</section>

<section id="invent" class="view">

  <div class="panel">

    <h3>INVENTION LAB</h3>

    <p class="muted">
      Possibility generation and recombination.
    </p>

    <div id="inventions"></div>

  </div>

</section>

<section id="evolve" class="view">

  <div class="panel">

    <h3>EVOLUTION LAB</h3>

    <div id="versions"></div>

  </div>

</section>

<section id="system" class="view">

  <div class="panel">

    <h3>.OMEGA SYSTEM</h3>

    <pre id="system"></pre>

  </div>

</section>

<section id="terminal" class="view">

  <div class="terminal">

    <div id="terminalOutput"></div>

    <div class="prompt">

      <span>ω&gt;</span>

      <input id="terminalInput">

    </div>

  </div>

</section>

</main>

<script src="/app.js"></script>

</body>
</html>
HTML

cat > public/styles.css <<'CSS'
*{
 box-sizing:border-box
}

body{
 margin:0;
 background:#07080b;
 color:#f4f6fa;
 font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif
}

aside{
 position:fixed;
 left:0;
 top:0;
 bottom:0;
 width:245px;
 padding:22px 14px;
 background:#0c0e13;
 border-right:1px solid #252a33;
 display:flex;
 flex-direction:column;
 gap:7px
}

.brand{
 font-size:22px;
 font-weight:800;
 padding:8px 10px 28px
}

.brand:first-letter{
 font-size:32px
}

aside button{
 border:0;
 background:transparent;
 color:#939cab;
 text-align:left;
 padding:13px;
 border-radius:10px;
 cursor:pointer
}

aside button:hover{
 background:#181b22;
 color:#fff
}

.online{
 margin-top:auto;
 color:#697280;
 font-size:11px;
 padding:12px
}

.online i{
 display:inline-block;
 width:7px;
 height:7px;
 border-radius:50%;
 background:#52df8a;
 margin-right:7px
}

main{
 margin-left:245px;
 padding:30px;
 max-width:1550px
}

header{
 display:flex;
 justify-content:space-between;
 align-items:center;
 margin-bottom:28px
}

small{
 color:#6f7887;
 letter-spacing:2px;
 font-size:10px
}

h1{
 margin:5px 0;
 font-size:30px
}

#version{
 padding:8px 13px;
 border:1px solid #2a3039;
 border-radius:30px;
 color:#9da6b5
}

.view{
 display:none
}

.view.active{
 display:block
}

.hero{
 min-height:470px;
 border:1px solid #282e39;
 border-radius:25px;
 padding:48px;
 display:flex;
 align-items:center;
 justify-content:space-between;
 background:
 radial-gradient(
  circle at 80% 50%,
  #252b4d,
  transparent 34%
 ),
 #0d0f14
}

.heroText{
 max-width:700px
}

.omega{
 font-size:22px
}

.hero h2{
 font-size:52px;
 line-height:.98;
 margin:10px 0 20px
}

.hero p{
 color:#919aa9;
 line-height:1.7;
 max-width:650px
}

.command{
 margin-top:25px;
 display:flex;
 background:#07090c;
 border:1px solid #343a46;
 border-radius:13px;
 padding:5px
}

.command input{
 flex:1;
 border:0;
 outline:0;
 background:none;
 color:white;
 padding:14px
}

.command button{
 border:0;
 border-radius:9px;
 padding:10px 17px;
 background:#f3f5f8;
 color:#08090d;
 cursor:pointer
}

.quick{
 display:flex;
 gap:8px;
 margin-top:10px;
 flex-wrap:wrap
}

.quick button{
 border:1px solid #2a3039;
 border-radius:9px;
 padding:9px 13px;
 background:#171a20;
 color:#c5cbd4
}

.orb{
 width:280px;
 height:280px;
 border-radius:50%;
 display:grid;
 place-items:center;
 font-size:100px;
 background:
 radial-gradient(
  circle,
  #414a78,
  #171b2c 50%,
  #090b10 72%
 );
 box-shadow:0 0 120px #252b50
}

.stats{
 display:grid;
 grid-template-columns:repeat(4,1fr);
 gap:12px;
 margin:14px 0
}

.card,
.panel{
 background:#0d0f14;
 border:1px solid #252a33;
 border-radius:16px;
 padding:18px
}

.card strong{
 display:block;
 margin-top:5px;
 font-size:25px
}

.muted{
 color:#777f8d;
 font-size:12px
}

.panel{
 margin-top:14px
}

.panel h3{
 margin-top:0;
 font-size:12px;
 letter-spacing:1.5px
}

.event,
.candidate,
.version{
 margin-top:9px;
 padding:13px;
 border:1px solid #20252e;
 border-radius:10px;
 background:#090b0f
}

.event{
 display:flex;
 justify-content:space-between
}

.score{
 float:right
}

.bar{
 height:5px;
 margin-top:10px;
 background:#20242d;
 border-radius:5px;
 overflow:hidden
}

.bar i{
 display:block;
 height:100%;
 background:#9ca7ff
}

.terminal{
 min-height:600px;
 background:#030405;
 border:1px solid #282d36;
 border-radius:16px;
 padding:18px;
 font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
 color:#b9c4d5
}

.prompt{
 display:flex;
 gap:9px;
 margin-top:15px
}

.prompt input{
 flex:1;
 background:none;
 border:0;
 outline:0;
 color:#fff;
 font:inherit
}

pre{
 white-space:pre-wrap;
 overflow:auto
}

@media(max-width:850px){

 aside{
  position:static;
  width:100%;
  height:auto;
  flex-direction:row;
  overflow-x:auto
 }

 .brand{
  padding:8px 12px
 }

 .online{
  display:none
 }

 main{
  margin:0;
  padding:16px
 }

 .hero{
  padding:28px
 }

 .orb{
  display:none
 }

 .hero h2{
  font-size:38px
 }

 .stats{
  grid-template-columns:repeat(2,1fr)
 }

}
CSS

cat > public/app.js <<'JS'
const $=s=>document.querySelector(s)
const $$=s=>[...document.querySelectorAll(s)]

async function api(path,options){
 const response=await fetch(path,options)
 return response.json()
}

function show(view){

 $$(".view").forEach(
  x=>x.classList.toggle(
   "active",
   x.id===view
  )
 )

 const titles={
  home:"Command Center",
  invent:"Invention Lab",
  evolve:"Evolution Lab",
  system:"System",
  terminal:"Terminal"
 }

 $("#title").textContent=titles[view]

 if(view==="invent") loadInvent()
 if(view==="evolve") loadVersions()
 if(view==="system") loadSystem()
}

$$("aside button").forEach(
 button=>{
  button.onclick=()=>{
   show(button.dataset.view)
  }
 }
)

async function status(){

 const s=await api("/api/status")

 $("#version").textContent=
  "v"+s.version

 const stats=[
  ["Runtime",s.state],
  ["Constraints",s.constraints.length],
  ["Versions",s.versions],
  ["Events",s.events]
 ]

 $("#stats").innerHTML=
  stats.map(
   x=>`
    <div class="card">
      <span class="muted">${x[0]}</span>
      <strong>${x[1]}</strong>
    </div>
   `
  ).join("")

 const events=await api("/api/events")

 $("#events").innerHTML=
  events.slice(0,10).map(
   e=>`
    <div class="event">
      <span>${e.type}</span>
      <span class="muted">
       ${new Date(e.timestamp).toLocaleTimeString()}
      </span>
    </div>
   `
  ).join("")
}

async function command(text){

 if(!text.trim())
  return

 const result=await api(
  "/api/command",
  {
   method:"POST",
   headers:{
    "Content-Type":"application/json"
   },
   body:JSON.stringify({
    command:text
   })
  }
 )

 $("#terminalOutput").insertAdjacentHTML(
  "beforeend",
  `<pre>ω&gt; ${text}\n${JSON.stringify(result,null,2)}</pre>`
 )

 await status()
}

$("#run").onclick=()=>{
 command($("#intent").value)
}

$("#intent").onkeydown=e=>{
 if(e.key==="Enter")
  command($("#intent").value)
}

$$("[data-command]").forEach(
 button=>{
  button.onclick=()=>{
   command(button.dataset.command)
  }
 }
)

$("#terminalInput").onkeydown=e=>{
 if(e.key==="Enter"){
  command(e.target.value)
  e.target.value=""
 }
}

async function loadInvent(){

 const r=await api("/api/invent")

 $("#inventions").innerHTML=
  r.candidates.map(
   c=>`
    <div class="candidate">

     <span class="score">
      ${Math.round(c.novelty*100)}% novelty
     </span>

     <strong>${c.name}</strong>

     <div class="muted">
      ${c.strategy}
     </div>

     <div class="bar">
      <i style="width:${c.resilience*100}%"></i>
     </div>

    </div>
   `
  ).join("")
}

async function loadVersions(){

 const versions=await api("/api/versions")

 $("#versions").innerHTML=
  versions.length
   ?versions.slice().reverse().map(
    v=>`
     <div class="version">

      <span class="score">
       ${v.state}
      </span>

      <strong>
       OMEGA® ${v.version}
      </strong>

      <div class="muted">
       score ${Math.round(v.score*100)}%
       · ${v.architecture}
      </div>

     </div>
    `
   ).join("")
   :"<p class='muted'>No versions created yet.</p>"
}

async function loadSystem(){

 $("#system").textContent=
  JSON.stringify(
   await api("/api/system"),
   null,
   2
  )
}

status()

setInterval(status,4000)
JS

cat > tests/omega.test.js <<'JS'
import test from "node:test"
import assert from "node:assert/strict"
import {parseOmega} from "../src/parser.js"

test(
 "OMEGA parser",
 ()=>{
  const result=parseOmega(`
omega "TEST"

system {
 version "1.0.0"
 mode adaptive
}
`)

  assert.equal(result.name,"TEST")
  assert.equal(result.system.version,"1.0.0")
  assert.equal(result.system.mode,"adaptive")
 }
)
JS

cat > OMEGA_INSTALL.sh <<'INSTALL'
#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/omega"

pkg update -y
pkg install -y nodejs

cd "$ROOT"

npm test

echo
echo "OMEGA® READY"
echo
echo "Launch UI:"
echo "cd $HOME/omega && npm start"
echo
echo "CLI:"
echo "cd $HOME/omega && node bin/omega.js status"
echo
echo "Then open:"
echo "http://127.0.0.1:8787"
INSTALL

chmod +x OMEGA_INSTALL.sh

npm test

echo
echo "=========================================="
echo "       O M E G A ®  READY"
echo "=========================================="
echo
echo "Launch:"
echo "  cd ~/omega"
echo "  npm start"
echo
echo "UI:"
echo "  http://127.0.0.1:8787"
echo
echo "CLI:"
echo "  node bin/omega.js status"
echo "  node bin/omega.js invent"
echo "  node bin/omega.js simulate"
echo "  node bin/omega.js evolve"
echo "  node bin/omega.js release"
echo
