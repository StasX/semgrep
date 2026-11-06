FROM python:3.13-alpine

RUN apk upgrade --no-cache \
    && apk add --no-cache git=2.54.0-r0 ca-certificates=20261020-r0

COPY requirements.txt /tmp/requirements.txt

RUN python -m venv /opt/semgrep-venv \
    && /opt/semgrep-venv/bin/python -m pip install --no-cache-dir \
        --upgrade -r /tmp/requirements.txt \
    && /opt/semgrep-venv/bin/python -m pip check

ENV PATH="/opt/semgrep-venv/bin:$PATH" \
    HOME="/home/semgrep" \
    SEMGREP_SEND_METRICS="off" \
    SEMGREP_ENABLE_VERSION_CHECK="0"

RUN addgroup --gid 10001 --system semgrep \
    && adduser --uid 10001 --system --ingroup semgrep --home /home/semgrep semgrep \
    && mkdir /workspace \
    && chown semgrep:semgrep /workspace

WORKDIR /workspace
USER 10001:10001

ENTRYPOINT ["semgrep"]
CMD ["--help"]
