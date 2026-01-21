FROM alpine:3.21

WORKDIR /app

# Docker buildx 会在构建时自动填充这些变量
ARG TARGETOS
ARG TARGETARCH

COPY vigilantMonitor-agent-${TARGETOS}-${TARGETARCH} /app/vigilantMonitor-agent

RUN chmod +x /app/vigilantMonitor-agent

RUN touch /.vigilantMonitor-agent-container

ENTRYPOINT ["/app/vigilantMonitor-agent"]
# 运行时请指定参数
# Please specify parameters at runtime.
# eg: docker run vigilantMonitor-agent -e example.com -t token
CMD ["--help"]