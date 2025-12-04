# Matter Certification Container

This image packages a ready-to-run Project CHIP checkout and virtual environment so tests can run without rebuilding the toolchain on every invocation.

## Build

```sh
docker build -t matter-tests:latest --build-arg CHIP_VERSION=v1.4.2.0 .
```

Adjust `CHIP_VERSION` if you need a different release tag or branch.

## Pull from GHCR

If the CI workflow has already published an image, pull it directly from GitHub Container Registry:

```sh
docker pull ghcr.io/flipperdevices/matter-tests:latest
```

You can run the image via the fully qualified name or retag it locally for brevity:

```sh
docker tag ghcr.io/flipperdevices/matter-tests:latest matter-tests:latest
```

## Run Tests

```sh
docker run --rm -it \
  --network=host \
  --volume "$PWD/paa-store:/paa-store" \
  --volume "$PWD/storage:/storage" \
  matter-tests:latest
```

Inside the container:

```sh
cd /opt/connectedhomeip
source /python_env/bin/activate
python3 src/python_testing/TC_SC_4_3.py \
  --commissioning-method on-network \
  --discriminator 1300 \
  --passcode 2594278 \
  --paa-trust-store-path /paa-store \
  --storage-path /storage/admin_storage.json
```

`/python_env` is already on the `PATH`, so activating the environment is optional if you prefer to run `python3` directly.

## Notes

- Builder dependencies are pruned from the final runtime layer so the image stays small but still contains the CHIP source tree and compiled Python dependencies. Only the shared libraries and lightweight diagnostics needed for running tests remain; install extra packages in a derived image if you need additional tooling.
- The runtime stage sets `PIP_BREAK_SYSTEM_PACKAGES=1` which matches the expectations of CHIP's bootstrap scripts and allows ad-hoc pip installs when debugging tests.
- Mount `paa-store` and `storage` as volumes (as shown above) so credentials and test artifacts persist outside the container.
