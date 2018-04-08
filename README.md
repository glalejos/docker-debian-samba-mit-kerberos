# docker-debian-samba-mit-kerberos
A Debian-based Dockerfile that prepares the environment required to build Samba with MIT Kerberos support.

The resulting image contains Samba DEB packages compiled with MIT Kerberos supoprt (check `SAMBA_DEB_DIR` environment variable). Note that this image is intended to be used as a source image in a multi-stage build rather than as a base for production deployments.

For stability reasons, this image is built from _buster-20180213_, but should work for future _Buster_ releases. If you find _docker-debian-samba-mit-kerberos_ failing for a specific _Buster_ image, please, fill in an issue.
