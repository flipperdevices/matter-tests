FROM ubuntu:24.04 AS builder

ARG CHIP_VERSION=v1.4.2.0
ENV DEBIAN_FRONTEND=noninteractive \
	PIP_NO_CACHE_DIR=1 \
	PIP_BREAK_SYSTEM_PACKAGES=1 \
	CHIP_ROOT=/opt/connectedhomeip

SHELL ["/bin/bash", "-c"]

WORKDIR /opt

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		git \
		curl \
		ca-certificates \
		build-essential \
		pkg-config \
		ninja-build \
		python3 \
		python3-pip \
		python3-venv \
		python3-dev \
		python-is-python3 \
		libglib2.0-dev-bin \
		libglib2.0-dev \
		libcairo2-dev \
		libgirepository1.0-dev \
		libdbus-glib-1-dev && \
	rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 -b "${CHIP_VERSION}" https://github.com/project-chip/connectedhomeip "${CHIP_ROOT}"

WORKDIR ${CHIP_ROOT}

RUN source ./scripts/bootstrap.sh && \
	./scripts/checkout_submodules.py --shallow --platform linux

RUN source ./scripts/activate.sh && \
	./scripts/build_python.sh -i /python_env

RUN rm -rf .git \
	&& rm -rf \
		.environment \
		out \
		tmp \
        third_party \
	&& find . -type d -name '__pycache__' -prune -exec rm -rf '{}' + \
	&& find . -type f -name '*.pyc' -delete \
	&& rm -rf /root/.cache/pip /root/.cache/ninja

FROM ubuntu:24.04 AS runtime

ARG CHIP_VERSION=v1.4.2.0
ENV DEBIAN_FRONTEND=noninteractive \
	PIP_NO_CACHE_DIR=1 \
	PIP_BREAK_SYSTEM_PACKAGES=1 \
	CHIP_ROOT=/opt/connectedhomeip \
	VIRTUAL_ENV=/python_env \
	PATH="/python_env/bin:${PATH}"

SHELL ["/bin/bash", "-c"]

WORKDIR /opt

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		python3 \
		ca-certificates \
		libglib2.0-0 \
		libglib2.0-bin \
		libcairo2 \
		libgirepository-1.0-1 \
		libdbus-glib-1-2 \
		dbus \
		iproute2 \
		less \
		procps && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder ${CHIP_ROOT} ${CHIP_ROOT}
COPY --from=builder /python_env /python_env

WORKDIR ${CHIP_ROOT}

RUN printf '#!/bin/bash\nsource /python_env/bin/activate\nexec "$@"\n' > /usr/local/bin/matter-entrypoint && \
	chmod +x /usr/local/bin/matter-entrypoint

ENTRYPOINT ["/usr/local/bin/matter-entrypoint"]

CMD ["/bin/bash"]
