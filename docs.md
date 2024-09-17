# Documentación de los pasos

1. `mix phx.new mono_app --live` para crear el proyecto de LiveView.
2. `docker network create kafka_network` crear la red local para la comunicación de Kafka sin exponer puertos al host, usando nombres de contenedor en lugar de direcciones IP.
3. Agregar las imágenes de Kafka y Zookeeper localmente.
4. Agregar la dependencia a `mix.exs` a Kafka.
5. Usar `mix deps.get` para instalar las dependencias.