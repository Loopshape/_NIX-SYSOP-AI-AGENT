FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y curl git jq nodejs npm python3 python3-pip zstd
RUN curl -fsSL https://ollama.com/install.sh | sh
WORKDIR /nexus
COPY . .
RUN npm install ws sqlite3
RUN pip install sentence-transformers
EXPOSE 2244
CMD ["bash", "ai.sh"]