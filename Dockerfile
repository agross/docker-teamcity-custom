FROM agross/teamcity
LABEL maintainer "Alexander Groß <agross@therightstuff.de>"

# Pass address of LDAPS server using TRUST_CERT environment variable,
# e.g. "ldaps.example.com:636".
ARG TRUST_CERT
# Work around a bug in Synology's docker where ARG is not available as an environment variable.
# Docker version 17.05.0-ce, build 34ed091-synology
ENV TRUST_CERT $TRUST_CERT

# Support HTTPS NuGet feeds with embedded https URLs.
RUN sed --in-place --expression 's_.*tcpNoDelay="1".*$_&\
                                 secure="true"\
                                 scheme="https"\
                                 proxyPort="443"_' \
        conf/server.xml

# Add trusted certificate for LDAPS server.
USER root

RUN echo -n | \
    openssl s_client -connect $TRUST_CERT | \
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "/tmp/$TRUST_CERT" && \
    \
    "$JAVA_HOME/bin/keytool" -import \
                             -alias "$TRUST_CERT" \
                             -file "/tmp/$TRUST_CERT" \
                             -keystore "$JAVA_HOME/jre/lib/security/cacerts" \
                             -noprompt \
                             -storepass changeit && \
    \
    rm "/tmp/$TRUST_CERT"

USER teamcity
