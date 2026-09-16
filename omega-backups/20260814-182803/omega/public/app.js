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
