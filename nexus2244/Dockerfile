FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y curl git jq nodejs npm python3 python3-pip
RUN curl -fsSL https://ollama.com/install.sh | sh
WORKDIR /nexus
COPY . .
RUN npm install ws sqlite3
# Note: sentence-transformers might be large, but requested.
# Using --break-system-packages if needed on newer Ubuntu
RUN pip3 install sentence-transformers --break-system-packages
EXPOSE 2244
CMD ["bash", "ai.sh"]
