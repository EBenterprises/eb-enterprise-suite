import os from "node:os"

export function resources() {
    const total = os.totalmem()
    const free = os.freemem()
    const used = total - free

    return {
        cpuCount: os.cpus().length,
        totalMemory: total,
        freeMemory: free,
        usedMemory: used,
        memoryPressure:
            Math.round(
                used / total * 100
            ),
        platform: process.platform,
        arch: process.arch,
        node: process.version,
        uptime: os.uptime()
    }
}
