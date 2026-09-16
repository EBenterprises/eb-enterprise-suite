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
