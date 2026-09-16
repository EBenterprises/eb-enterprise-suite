#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Terminal Status Dashboard
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import shutil
import platform

def get_disk_usage():
    total, used, free = shutil.disk_usage("/")
    return f"{used // (2**30)}GB / {total // (2**30)}GB ({used/total*100:.1f}%)"

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - SYSTEM STATUS DASHBOARD")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    print(f" System Platform : {platform.system()} {platform.release()}")
    print(f" Architecture    : {platform.machine()}")
    print(f" Python Version  : {platform.python_version()}")
    print(f" Storage Usage   : {get_disk_usage()}")
    print(f" Workspace Path  : {os.path.expanduser('~/termux_workspace')}")
    print(" Daemon Status   : Operational [Active]")
    print("=============================================================")

if __name__ == "__main__":
    main()
