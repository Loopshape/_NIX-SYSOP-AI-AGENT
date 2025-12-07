OLLAMA="/home/linuxbrew/.linuxbrew/bin/ollama"  # absolute path injected by install_loop.sh
#!/usr/bin/env python3
import subprocess, hashlib, json, sys, time, concurrent.futures

AGENTS = [
    ("core","gemma3-1b"),
    ("loop","gemma3-1b"),
    ("wave","deepseek-coder"),
    ("coin","gemma3-1b"),
    ("code","deepseek-coder")
]

OUTPUT_DIR = "/home/loop/_/ai_orchestrator/results"

def run_ollama(agent_name, model, prompt):
    try:
        result = subprocess.run(["ollama","run",model],
                                input=prompt.encode("utf-8"),
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                timeout=120)
        tokens = result.stdout.decode("utf-8").strip()
        sha256 = hashlib.sha256(tokens.encode("utf-8")).hexdigest()
        md5 = hashlib.md5(tokens.encode("utf-8")).hexdigest()
        return {"agent":agent_name,"model":model,"tokens":tokens,"sha256":sha256,"md5":md5,"timestamp":time.time()}
    except Exception as e:
        return {"agent":agent_name,"error":str(e)}

def assemble_final(sorted_responses):
    merged = "\n\n".join([r["tokens"] for r in sorted_responses])
    html = f"""<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>AI Crew Output</title>
<style>body{{background:#111;color:#eee;font-family:monospace;margin:2rem;}}pre{{background:#222;padding:1rem;border-radius:8px;}}</style>
</head><body><pre>{merged}</pre></body></html>"""
    return html

def main():
    if len(sys.argv)<2:
        print(json.dumps({"error":"No prompt passed"}))
        return
    user_prompt=sys.argv[1]
    responses=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as exec:
        futures=[exec.submit(run_ollama,name,model,user_prompt) for (name,model) in AGENTS]
        for f in concurrent.futures.as_completed(futures):
            responses.append(f.result())
    valid=[r for r in responses if "tokens" in r]
    sorted_responses=sorted(valid,key=lambda x:x["sha256"])
    final_html=assemble_final(sorted_responses)
    with open(f"{OUTPUT_DIR}/final.html","w") as f:
        f.write(final_html)
    print(json.dumps({"status":"ok","agents":responses,"html_output":f"{OUTPUT_DIR}/final.html"},indent=2))

if __name__=="__main__":
    main()
