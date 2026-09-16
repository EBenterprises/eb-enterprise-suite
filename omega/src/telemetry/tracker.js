const records = []

export const track = event => {
  const record = {
    id: records.length + 1,
    timestamp: new Date().toISOString(),
    ...event
  }

  records.push(record)
  return record
}

export const recent = limit =>
  records.slice(-Number(limit || 20))

export const count = () =>
  records.length
