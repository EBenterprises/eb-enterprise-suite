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
