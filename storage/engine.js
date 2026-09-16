const fs = require('fs');
const path = require('path');

class DistributedLSMStore {
    constructor(dbDir) {
        this.dbDir = dbDir;
        this.memTable = new Map();
        this.walPath = path.join(dbDir, 'commit.wal');
        this.sstableDir = path.join(dbDir, 'sstables');
        
        if (!fs.existsSync(this.dbDir)) fs.mkdirSync(this.dbDir, { recursive: true });
        if (!fs.existsSync(this.sstableDir)) fs.mkdirSync(this.sstableDir, { recursive: true });
        
        this._recoverWAL();
    }

    _recoverWAL() {
        if (fs.existsSync(this.walPath)) {
            const data = fs.readFileSync(this.walPath, 'utf8');
            const lines = data.split('\n');
            for (let line of lines) {
                if (!line.trim()) continue;
                try {
                    const entry = JSON.parse(line);
                    this.memTable.set(entry.key, entry.value);
                } catch (e) {}
            }
        }
    }

    put(key, value) {
        this.memTable.set(key, value);
        const walEntry = JSON.stringify({ key, value, timestamp: Date.now() }) + '\n';
        fs.appendFileSync(this.walPath, walEntry);
        
        if (this.memTable.size >= 1000) {
            this._flushToSSTable();
        }
    }

    get(key) {
        if (this.memTable.has(key)) return this.memTable.get(key);
        // Fallback search across SSTable segments
        const sstables = fs.readdirSync(this.sstableDir).sort().reverse();
        for (let sstable of sstables) {
            const content = fs.readFileSync(path.join(this.sstableDir, sstable), 'utf8');
            const table = JSON.parse(content);
            if (table[key] !== undefined) return table[key];
        }
        return null;
    }

    _flushToSSTable() {
        const sstableData = Object.fromEntries(this.memTable);
        const sstaname = `sstable_${Date.now()}.json`;
        fs.writeFileSync(path.join(this.sstableDir, sstaname), JSON.stringify(sstableData));
        this.memTable.clear();
        fs.writeFileSync(this.walPath, ''); // Reset WAL
    }

    getAll() {
        let results = {};
        const sstables = fs.readdirSync(this.sstableDir);
        for (let sstable of sstables) {
            const content = fs.readFileSync(path.join(this.sstableDir, sstable), 'utf8');
            Object.assign(results, JSON.parse(content));
        }
        for (let [k, v] of this.memTable.entries()) {
            results[k] = v;
        }
        return Object.values(results);
    }
}

module.exports = DistributedLSMStore;
