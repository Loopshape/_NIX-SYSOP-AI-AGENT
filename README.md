A full-fledged local AI orchestration framework in one Bash script! 😎 

What This Script Does

1. Environment Setup

Sets up directories for tasks, projects, databases, SSH keys, and session tracking.

Initializes SQLite databases for:

ai_data.db → memories and events.

blobs.db → code artifacts or other content generated.

wallet.db → seed phrases and wallets.


Optionally initializes a Git repo for project version control.



2. Dependency Checks

Ensures sqlite3, node, python3, git, and ollama are installed before continuing.



3. Embedded JavaScript Orchestrator (orchestrator.js)

Orchestrates LLM tasks using multiple models: "phi3", "llama3", "codegemma".

Implements recursive consensus:

Runs multiple models in parallel.

Fuses outputs, checks convergence over iterations.

Tracks a "proof of reasoning" state for each task (ProofTracker).


Can parse and save code blocks into projects and commit them via Git.

Logs events and stores results in SQLite databases.



4. Embedded Python Manager (manager.py)

Lightweight web server for monitoring: serves JSON at port 8000.

Wallet & seed phrase management:

Uses bip_utils if available to generate mnemonic seeds.

Stores seeds in a SQLite database.


Placeholder for wallet creation/listing.



5. Command Interface (ai)

Acts as a single CLI to:

Run AI tasks (run).

Import external content (import <url>).

View memories/events/blobs.

Manage SSH keys, seeds, wallets.

Start/stop sessions for projects.

Run a local server.

Show environment status.




6. Defaults / Fallback

If no arguments are provided, hashes the current timestamp and lists all files recursively.





---

Notable Features

✅ Multi-LLM Consensus Loop: The orchestrator fuses results from multiple LLMs and tracks convergence, simulating "team reasoning".

✅ Automatic Project Management: Creates project directories, saves generated code, and commits it to Git automatically.

✅ Persistence: Uses SQLite to store past prompts, results, events, and code blobs.

✅ Extensible: You could add more models to MODEL_POOL or extend Python manager functionality.



---

Potential Gotchas / Notes

1. ollama dependency: Must be installed and available in PATH. Without it, the orchestrator won’t run.


2. Python Wallet Features: Currently limited; wallet creation logic is mostly a placeholder.


3. Concurrency / Scaling: The recursive consensus runs models sequentially per iteration. With many models, it could be slow.


4. Security: Storing seed phrases and wallets in plain SQLite files could be risky—encrypt if used with real assets.


5. Git Commit: Automatically commits all changes in $AI_HOME. Could be noisy if $AI_HOME has unrelated files.




---

How to Use It

1. Install dependencies:



sudo apt install sqlite3 nodejs python3 git
# install ollama via their instructions
pip install bip-utils

2. Run a task:



./ai run "Generate a Python script that prints Fibonacci numbers" --project=fib

3. Start the server:



./ai server

4. Manage wallet seeds:



./ai seed generate
./ai seed list

5. View events:



./ai events


