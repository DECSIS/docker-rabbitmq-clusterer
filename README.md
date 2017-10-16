# docker-rabbitmq-clusterer

[![Build Status](https://travis-ci.org/DECSIS/docker-rabbitmq-clusterer.svg?branch=master)](https://travis-ci.org/DECSIS/docker-rabbitmq-clusterer)

This Docker image aims to provide a convinient way to launch rabbitmq clusters using the [rabbitmq-clusterer](https://github.com/rabbitmq/rabbitmq-clusterer) plugin.

It provides two way to achieve this. One using environment variables to defines the cluster nodes and gospel node and other using Rancher [metadata service](http://docs.rancher.com/rancher/v1.2/en/rancher-services/metadata-service/) to deploy in [Rancher](http://rancher.com) managed environments.

Clusterer version: rabbitmq_clusterer-3.6.x-667f92b0
Tested in Rancher 1.2.0

![rancher demo gif](http://i.imgur.com/A1G3Aim.gif)

## ENV Variables based cluster

### CLUSTER_NODES 

Fill accordingly [clusterer configuration](https://github.com/rabbitmq/rabbitmq-clusterer#cluster-configuration). Only the nodes array content should be defined here:
    
    CLUSTER_NODES="rabbit@hostA, {rabbit@hostD, disk}, {rabbit@hostB, ram}"

### CLUSTER_GOSPEL_NODE

Fill accordingly [clusterer configuration](https://github.com/rabbitmq/rabbitmq-clusterer#cluster-configuration). Only the node name is necessary here:

    CLUSTER_GOSPEL_NODE=rabbit@hostA
    
**Launch a one node cluster:**
    
    docker run --rm -it --network=rabbitmqnet --hostname=NODE1 --name=NODE1 -e RABBITMQ_ERLANG_COOKIE='VERYSTRONGCOOKIE' -e CLUSTER_NODES=rabbit@NODE1 -e CLUSTER_GOSPEL_NODE=rabbit@NODE1 decsis/rabbitmq-clusterer
    
You must have noticed that I'm using a user-defined network. That is necessary for making use of the [Embedded DNS server](https://docs.docker.com/engine/userguide/networking/configure-dns/) that Docker provides in such networks. Also both `hostname` and `name` are necessary. The `name` is for Docker serve the DNS entry with that name. The `hostname` is for each rabbit node recognize itself.

Finally the `RABBITMQ_ERLANG_COOKIE` must be set and be equal in all nodes all described in the [RabbitMQ docs](https://www.rabbitmq.com/clustering.html#erlang-cookie).

**Launch a second node:**

    docker run --rm -it --network=rabbitmqnet --hostname=NODE2 --name=NODE2 -e RABBITMQ_ERLANG_COOKIE='VERYSTRONGCOOKIE' -e CLUSTER_NODES="rabbit@NODE1,rabbit@NODE2" -e CLUSTER_GOSPEL_NODE=rabbit@NODE1 decsis/rabbitmq-clusterer
    
If the container appears to be hanged is default rabbitmq-clusterer behaviour to wait indefinitly for all the necessary conditions to create the configured cluster so it is indicative of something missing (can be a missing running node, a network access problem or something alike).

## Rancher Metadata based cluster

For this method is assumed that all nodes are part of the same Rancher service. Is necessary to set the variable:

    RANCHER_MANAGED_CLUSTER=true

And you also have to instruct Rancher to use the container name as hostname.

Rancher `docker-compose.yml` example:

    version: '2'
    services:
      rabbit:
        image: decsis/rabbitmq-clusterer
        environment:
          RABBITMQ_ERLANG_COOKIE: ASTRONGERCOOKIE
          RANCHER_MANAGED_CLUSTER: 'true'        
        labels:          
          io.rancher.container.hostname_override: container_name
          
Then you just scale it up or down and the magic happens.
