#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Automated Integration Test Suite
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import subprocess
import sys

def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return res.returncode, res.stdout, res.stderr

def test_cli():
    code, out, err = run_cmd("./exec-spec status")
    assert code == 0, f"Status failed: {err}"
    print("[✓] CLI status command passed")

    code, out, err = run_cmd("./exec-spec verify")
    assert code == 0, f"Verify failed: {err}"
    print("[✓] CLI verify command passed")

    code, out, err = run_cmd("./exec-spec analytics")
    assert code == 0, f"Analytics failed: {err}"
    print("[✓] CLI analytics command passed")

if __name__ == "__main__":
    print("Running Executive Spectrum Integration Tests...")
    try:
        test_cli()
        print("[+] All integration tests passed successfully.")
    except AssertionError as e:
        print(f"[-] Test failed: {e}")
        sys.exit(1)
