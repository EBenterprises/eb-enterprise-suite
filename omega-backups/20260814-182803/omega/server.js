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
