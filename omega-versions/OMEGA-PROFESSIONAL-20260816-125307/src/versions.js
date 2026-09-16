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
