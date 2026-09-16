#!/usr/init/env python3
import os
import glob
import json
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
MAX_SIZE_BYTES = 5 * 1024 * 1024 # 5 MB threshold for rotation

def analyze_and_rotate_logs():
    log_files = glob.glob(os.path.join(WORKSPACE_DIR, '*.log')) + glob.glob(os.path.join(WORKSPACE_DIR, '*.jsonl'))
    summary = {
        "timestamp": datetime.datetime.now().isoformat(),
        "analyzed_files": []
    }

    for path in log_files:
        filename = os.path.basename(path)
        size = os.path.getsize(path)
        error_count = 0
        
        try:
            with open(path, 'r', errors='ignore') as f:
                lines = f.readlines()
                for line in lines:
                    if 'ERROR' in line or '[-] ' in line or 'Exception' in line:
                        error_count += 1
        except Exception:
            pass

        file_info = {
            "filename": filename,
            "size_bytes": size,
            "error_count": error_count,
            "rotated": False
        }

        # Rotate if size exceeds limit
        if size > MAX_SIZE_BYTES:
            archive_path = f"{path}.{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.bak"
            os.rename(path, archive_path)
            file_info["rotated"] = True
            file_info["archive"] = os.path.basename(archive_path)

        summary["analyzed_files"].append(file_info)

    report_path = os.path.join(WORKSPACE_DIR, 'log_analysis_report.json')
    with open(report_path, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(json.dumps(summary, indent=2))

if __name__ == '__main__':
    analyze_and_rotate_logs()
