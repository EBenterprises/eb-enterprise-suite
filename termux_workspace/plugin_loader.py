#!/usr/bin/env python3
import os
import importlib.util
import sys

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
PLUGINS_DIR = os.path.join(WORKSPACE_DIR, 'plugins')

def load_plugins():
    if not os.path.exists(PLUGINS_DIR):
        print("[*] No plugins directory found.")
        return

    loaded = []
    for filename in os.listdir(PLUGINS_DIR):
        if filename.endswith('.py') and filename != '__init__.py':
            plugin_path = os.path.join(PLUGINS_DIR, filename)
            plugin_name = filename[:-3]
            try:
                spec = importlib.util.spec_from_file_location(plugin_name, plugin_path)
                mod = importlib.util.module_from_spec(spec)
                sys.modules[plugin_name] = mod
                spec.loader.exec_module(mod)
                if hasattr(mod, 'register'):
                    mod.register()
                loaded.append(plugin_name)
                print(f"[+] Successfully loaded plugin: {plugin_name}")
            except Exception as e:
                print(f"[-] Failed to load plugin {plugin_name}: {e}")
    print(f"=== Total plugins loaded: {len(loaded)} ===")

if __name__ == '__main__':
    load_plugins()
