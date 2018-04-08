FROM debian:buster-20180213 AS samba-mit-kerberos-build

ENV APT_QUIET_OPTIONS=--quiet\ --quiet\ --yes\ --ignore-missing

# 1. Prepare the system to download source code packages.
RUN	apt-get update ${APT_QUIET_OPTIONS} \
	&& cat /etc/apt/sources.list | sed -e 's/deb /deb-src /g' >> /etc/apt/sources.list \
	&& cat /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install dpkg-dev ${APT_QUIET_OPTIONS}

# 2. Download Samba code and dependencies.
# https://wiki.samba.org/index.php/Package_Dependencies_Required_to_Build_Samba
ENV SAMBA_DEBSRC_ROOT=/root/samba-src
WORKDIR ${SAMBA_DEBSRC_ROOT}
RUN	apt-get build-dep samba ${APT_QUIET_OPTIONS}
RUN	apt-get source samba ${APT_QUIET_OPTIONS}

# 2.1. Set the minimal configuration required to get the packages installed.
RUN	echo "krb5-config	krb5-config/default_realm	string	KERBEROSREALM" | debconf-set-selections \
	&& echo "krb5-config	krb5-config/kerberos_servers	string	kerberos.local" | debconf-set-selections \
	&& echo "krb5-config	krb5-config/admin_server	string	kerberos.local" | debconf-set-selections

# 2.2. Install packages mentioned by Samba package maintainer Louis: "For example ldb 1.2.3 tevent 0.9.34 talloc 2.1.10 tdb 1.3.15 and krb5 1.15.1"
# Every version in Buster matches those stated by Louis, but krb5, which is 1.16.
RUN	apt-get update && apt-get install ${APT_QUIET_OPTIONS} ldb-tools libtevent0 libtalloc2 libtdb1
RUN	apt-get update && apt-get install ${APT_QUIET_OPTIONS} krb5-admin-server krb5-doc krb5-gss-samples krb5-k5tls krb5-kdc krb5-kdc-ldap krb5-kpropd krb5-locales krb5-multidev krb5-otp krb5-pkinit krb5-user libgssapi-krb5-2 libgssrpc4 libk5crypto3 libkadm5clnt-mit11 libkadm5srv-mit11 libkdb5-9 libkrad-dev libkrad0 libkrb5-3 libkrb5-dbg libkrb5-dev libkrb5support0

# 2.3. Patch package build related files.
# Remove Heimdall references from debian/*.install files, as hinted by Samba package maintainer Mathieu.
# I used the following command to find and remove faulting lines:
# for i in libHDB-SAMBA4.so.0 libhdb-samba4.so.11 libhdb-samba4.so.11.0.2 libkdc-samba4.so.2 libkdc-samba4.so.2.0.0 libasn1-samba4.so.8 libasn1-samba4.so.8.0.0 libcom_err-samba4.so.0 libcom_err-samba4.so.0.25 libgssapi-samba4.so.2 libgssapi-samba4.so.2.0.0 libhcrypto-samba4.so.5 libhcrypto-samba4.so.5.0.1 libheimbase-samba4.so.1 libheimbase-samba4.so.1.0.0 libheimntlm-samba4.so.1 libheimntlm-samba4.so.1.0.1 libhx509-samba4.so.5 libhx509-samba4.so.5.0.0 libkrb5-samba4.so.26 libkrb5-samba4.so.26.0.0 libroken-samba4.so.19 libroken-samba4.so.19.0.1 libwind-samba4.so.0 libwind-samba4.so.0.0.0; do find . -type f | grep install | xargs -I '{}' sed -i \"/${i}/d\" '{}'; done;
COPY samba_mit_kerberos.diff /root/
RUN	cd $(ls -t | head -n 1) \
	&& patch -p2 -i /root/samba_mit_kerberos.diff

# 2.4. Build Samba package.
# This operation can take a lot to complete.
RUN	cd $(ls -t | head -n 1) \
	&& dpkg-buildpackage

# 2.5. Gather generated DEB files in another directory.
ENV SAMBA_DEB_DIR=/root/deb
RUN	mkdir -p ${SAMBA_DEB_DIR} \
	&& cp ${SAMBA_DEBSRC_ROOT}/*.deb ${SAMBA_DEB_DIR}
