#!/usr/bin/env python3
import os
import subprocess
import sqlite3

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def show_banner():
    print("=" * 60)
    print("      EB ENTERPRISES - EXECUTIVE SPECTRUM WORKSPACE TUI       ")
    print("=" * 60)

def main_menu():
    while True:
        clear_screen()
        show_banner()
        print("\n[1] View Workspace Status & Git Log")
        print("[2] Run Workspace Verification & Sync")
        print("[3] List Stored Code Snippets")
        print("[4] Tail Recent Workspace Logs")
        print("[5] Exit")
        
        choice = input("\nSelect an option [1-5]: ").strip()
        
        if choice == '1':
            clear_screen()
            print("--- Git Status & Recent Commits ---")
            subprocess.run(['git', 'status'])
            print("\n--- Recent Commits ---")
            subprocess.run(['git', 'log', '-n', '5', '--oneline'])
            input("\nPress Enter to return to menu...")
        elif choice == '2':
            clear_screen()
            subprocess.run(['./verify_and_deploy.sh'])
            input("\nPress Enter to return to menu...")
        elif choice == '3':
            clear_screen()
            print("--- Stored Snippets ---")
            subprocess.run(['python3', 'snippet_store.py', 'list'])
            input("\nPress Enter to return to menu...")
        elif choice == '4':
            clear_screen()
            print("--- Recent Workspace Logs ---")
            log_path = os.path.expanduser('~/termux_workspace/workspace.log')
            if os.path.exists(log_path):
                subprocess.run(['tail', '-n', '50', log_path])
            else:
                print("No workspace.log found yet.")
            input("\nPress Enter to return to menu...")
        elif choice == '5':
            print("Exiting TUI. Workspace running smoothly.")
            break
        else:
            input("Invalid selection. Press Enter to retry...")

if __name__ == '__main__':
    main_menu()
