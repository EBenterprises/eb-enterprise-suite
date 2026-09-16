#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Advanced Curses TUI Dashboard
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import curses
import os
import shutil
import platform
import datetime

def draw_menu(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(1)
    stdscr.timeout(1000)

    current_row = 0
    menu = ["System Status", "Snippet Manager", "Credential Vault", "Telemetry Analyzer", "System Verify", "Exit"]

    while True:
        stdscr.clear()
        h, w = stdscr.getmaxyx()

        title = " EXECUTIVE SPECTRUM - TERMINAL USER INTERFACE "
        stdscr.attron(curses.color_pair(1))
        stdscr.addstr(0, (w - len(title)) // 2, title)
        stdscr.attroff(curses.color_pair(1))

        # Render sidebar menu
        for idx, row in enumerate(menu):
            x = 4
            y = 4 + idx
            if idx == current_row:
                stdscr.attron(curses.A_REVERSE)
                stdscr.addstr(y, x, f" > {row} < ")
                stdscr.attroff(curses.A_REVERSE)
            else:
                stdscr.addstr(y, x, f"   {row}   ")

        # Render info panel
        panel_x = 30
        panel_y = 4
        stdscr.addstr(panel_y, panel_x, f"Platform      : {platform.system()} {platform.release()}")
        stdscr.addstr(panel_y + 1, panel_x, f"Architecture  : {platform.machine()}")
        stdscr.addstr(panel_y + 2, panel_x, f"Python Version: {platform.python_version()}")
        stdscr.addstr(panel_y + 3, panel_x, f"Time          : {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        total, used, free = shutil.disk_usage("/")
        stdscr.addstr(panel_y + 5, panel_x, f"Disk Usage    : {used // (2**30)}GB / {total // (2**30)}GB ({used/total*100:.1f}%)")

        footer = " Use Arrow Keys to Navigate | Enter to Select | 'q' to Quit "
        stdscr.addstr(h - 2, (w - len(footer)) // 2, footer)

        stdscr.refresh()

        key = stdscr.getch()
        if key == ord('q') or key == ord('Q'):
            break
        elif key == curses.KEY_UP and current_row > 0:
            current_row -= 1
        elif key == curses.KEY_DOWN and current_row < len(menu) - 1:
            current_row += 1
        elif key == ord('\n') or key == curses.KEY_ENTER:
            if menu[current_row] == "Exit":
                break
            elif menu[current_row] == "System Verify":
                stdscr.clear()
                stdscr.addstr(2, 4, "Running system verification...")
                stdscr.refresh()
                curses.napms(1000)

def main():
    try:
        curses.wrapper(draw_menu)
    except Exception as e:
        print(f"TUI Error: {e}")

if __name__ == "__main__":
    main()
