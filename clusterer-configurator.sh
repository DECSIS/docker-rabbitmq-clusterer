#!/bin/bash
set -e

set_config () {
	CLUSTER_VERSION=$(date +%s) \
	_CLUSTER_NODES=$1 \
	_CLUSTER_GOSPEL_NODE=$2 \
	envsubst < "/config/clusterer.config.template" > "/config/clusterer.config"	
}

rancher_metadata () {
	curl -s "http://rancher-metadata/2015-12-19/$1"
}

if [ ! -s /config/clusterer.config ]; then
	if $RANCHER_MANAGED_CLUSTER;  then
		echo "RANCHER MANAGED CLUSTER, using rancher-metadata to discover nodes"
		SELF=$(rancher_metadata "self/container/name")
		RANCHER_CLUSTER_NODES=$(rancher_metadata "self/service/containers" | sed -e 's#[0-9][0-9]*=#rabbit@#g' | xargs | sed -e "s/ /','/g" | sed -e "s/\(.*\)/'\1'/g")
		RANCHER_CLUSTER_GOSPEL_NODE=$(rancher_metadata "self/service/containers" | grep -v "$SELF" | tail -1 | sed -e 's#[0-9][0-9]*=#rabbit@#g' | sed -e "s/\(.*\)/'\1'/g")
		RANCHER_CLUSTER_GOSPEL_NODE="${RANCHER_CLUSTER_GOSPEL_NODE:-"'rabbit@$SELF'"}"
		echo "MY NAME IS: $SELF"
		echo "RANCHER_CLUSTER_NODES: $RANCHER_CLUSTER_NODES"
		echo "RANCHER_CLUSTER_GOSPEL_NODE: $RANCHER_CLUSTER_GOSPEL_NODE"
		set_config $RANCHER_CLUSTER_NODES $RANCHER_CLUSTER_GOSPEL_NODE;
	else
		set_config $CLUSTER_NODES $CLUSTER_GOSPEL_NODE;
	fi
	sed -i -e 's#]\.#, {rabbitmq_clusterer, [{config, "/config/clusterer.config"}] }]\.#g' /etc/rabbitmq/rabbitmq.config;
else
	echo "Configuration exists: "
	cat /config/clusterer.config
fi
exec rabbitmq-server-orig
