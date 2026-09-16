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
