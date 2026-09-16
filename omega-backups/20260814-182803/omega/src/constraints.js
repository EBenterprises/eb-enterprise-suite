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
