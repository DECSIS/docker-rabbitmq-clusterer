FROM rabbitmq:3.6-management

ENV RABBITMQ_CLUSTERER_VERSION 3.6.x-667f92b0
ENV RABBITMQ_BOOT_MODULE rabbit_clusterer
ENV RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS "-pa /plugins/rabbitmq_clusterer.ez/rabbitmq_clusterer-${RABBITMQ_CLUSTERER_VERSION}/ebin"
ENV RANCHER_MANAGED_CLUSTER=false

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget curl gettext-base && rm -rf /var/lib/apt/lists/* \
	&& wget -O /plugins/rabbitmq_delayed_message_exchange.ez "https://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_delayed_message_exchange-0.0.1.ez" \
    && rabbitmq-plugins enable rabbitmq_delayed_message_exchange  --offline \
    && wget -O /plugins/rabbitmq_clusterer.ez "https://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_clusterer-${RABBITMQ_CLUSTERER_VERSION}.ez" \
    && rabbitmq-plugins enable rabbitmq_clusterer --offline \
    && apt-get purge -y --auto-remove ca-certificates wget

COPY config /config

RUN chown -R rabbitmq /config && mv /usr/lib/rabbitmq/bin/rabbitmq-server /usr/lib/rabbitmq/bin/rabbitmq-server-orig
COPY clusterer-configurator.sh /usr/lib/rabbitmq/bin/rabbitmq-server
