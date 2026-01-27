FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt update && apt install -y \
    curl \
    git \
    jq \
    nodejs \
    npm \
    python3 \
    python3-pip \
    ca-certificates \
    sqlite3 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install Python dependencies
RUN pip3 install sentence-transformers numpy

WORKDIR /nexus

# Copy application files
COPY . .

# Install Node.js dependencies
RUN npm install ws sqlite3

EXPOSE 2244

CMD ["bash", "ai.sh"]