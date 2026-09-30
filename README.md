# Alpine APKs

Vendored Alpine packages and indexes for the Lightsquares enclave image.
Consumers pin this repository by commit and install without APK network access.

Run `./fetch.sh` with Podman to refresh the package closure. Keep the Alpine
image digest and package versions aligned with the consuming repository’s
`images/Dockerfile` and `images/shared/src/buildtime/setup-rootfs.sh`. Review
and commit the snapshot, then update the consumer’s submodule pointer and run
`make verify-reproducible-images` there.
