export OPENEMPI_HOME=/sysnet/openempi-3.3.0c/openempi-entity-3.3.0c
VMPARAMS=-Xms1024m -Xmx4096m
export JAVA_OPTS="${VMPARAMS} -Dopenempi.home=${OPENEMPI_HOME}"
