import glob

for path in glob.glob("**/server.js", recursive=True):
    with open(path, "r") as f:
        content = f.read()
    
    # Replace strict localhost/127.0.0.1 bindings with universal 0.0.0.0 or process.env.HOST
    new_content = content.replace("127.0.0.1", "0.0.0.0").replace("localhost", "0.0.0.0")
    
    with open(path, "w") as f:
        f.write(new_content)

print("[+] Updated server.js binding to 0.0.0.0")
