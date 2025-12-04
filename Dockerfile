FROM ubuntu:24.04

WORKDIR .

RUN apt update

RUN apt install -y git curl python3-pip python3-venv

RUN git clone --depth=1 -b v1.4.2.0 https://github.com/project-chip/connectedhomeip

WORKDIR connectedhomeip

RUN bash -c "source ./scripts/bootstrap.sh; ./scripts/checkout_submodules.py --shallow --platform linux"

RUN apt install -y libglib2.0-dev-bin libglib2.0-dev libcairo2-dev libgirepository1.0-dev libdbus-glib-1-dev

RUN bash -c "source ./scripts/activate.sh; ./scripts/build_python.sh -i /python_env"
