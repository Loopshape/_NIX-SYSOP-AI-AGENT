docker run -it \
  --name nexus-2244 \
  --restart=always \
  -v nexus-core:/opt/nexus/core \
  -v nexus-loop:/opt/nexus/loop \
  -v nexus-wave:/opt/nexus/wave \
  -v nexus-coin:/opt/nexus/coin \
  -v nexus-code:/opt/nexus/code \
  -v nexus-tmp:/opt/nexus/tmp \
  -v nexus-genesis:/opt/nexus/genesis \
  -v nexus-logs:/opt/nexus/logs \
  nexus/base:latest

