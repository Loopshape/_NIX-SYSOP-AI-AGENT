# 1. Update system & install dependencies
sudo apt update && sudo apt install -y curl unzip

# 2. Download Ollama CLI (replace with correct latest release for Linux)
# Example:
curl -L -o ~/ollama.zip "https://ollama.com/download/ollama-cli-linux.zip"
unzip ~/ollama.zip -d ~/ollama
rm ~/ollama.zip

# 3. Add Ollama CLI to PATH
echo 'export PATH="$HOME/ollama:$PATH"' >> ~/.profile
export PATH="$HOME/ollama:$PATH"

# 4. Test Ollama
ollama --version
