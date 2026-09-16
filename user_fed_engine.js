// User-Fed Expansion & Dynamic Codebase Registry Engine
// Allows the operator to inject, expand, and synthesize new modules, pages, or backend routes on-the-fly directly from runtime input.

const fs = require('fs');
const path = require('path');

class UserFedCodebaseManager {
    constructor() {
        this.registryPath = path.join(__dirname, 'user_fed_registry.json');
        this.loadRegistry();
    }

    loadRegistry() {
        if (fs.existsSync(this.registryPath)) {
            try {
                this.registry = JSON.parse(fs.readFileSync(this.registryPath, 'utf8'));
            } catch (e) {
                this.registry = { modules: [], routes: [], assets: [] };
            }
        } else {
            this.registry = { modules: [], routes: [], assets: [] };
            this.saveRegistry();
        }
    }

    saveRegistry() {
        fs.writeFileSync(this.registryPath, JSON.stringify(this.registry, null, 2));
    }

    injectModule(moduleName, fileType, codeContent) {
        let targetDir = path.join(__dirname, 'public');
        if (fileType === 'backend') {
            targetDir = __dirname;
        } else if (fileType === 'styles') {
            targetDir = path.join(__dirname, 'public');
        }

        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
        }

        const filePath = path.join(targetDir, moduleName);
        fs.writeFileSync(filePath, codeContent, 'utf8');

        this.registry.modules.push({
            name: moduleName,
            type: fileType,
            path: filePath,
            timestamp: new Date().toISOString()
        });
        this.saveRegistry();

        console.log(`[USER-FED] Successfully expanded codebase: ${moduleName} (${fileType})`);
        return { success: true, filePath };
    }

    getRegistry() {
        return this.registry;
    }
}

module.exports = UserFedCodebaseManager;
