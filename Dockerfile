# Etapa 1: Construcción de Assets (Frontend)
FROM node:18-bullseye AS assets-builder
WORKDIR /app/assets
COPY assets/package.json ./
RUN npm cache clean --force && npm install --no-progress --verbose
COPY assets/ .
RUN npm run build
RUN ls -la /app/assets/priv/static || echo "Assets no generados correctamente en /app/assets/priv/static"

# Etapa 2: Construcción de la Aplicación Elixir (Backend)
FROM elixir:1.17.2 AS phx-builder
RUN apt-get update && apt-get install -y --no-install-recommends build-essential git curl && rm -rf /var/lib/apt/lists/*
ENV MIX_ENV=prod
WORKDIR /opt/app
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
RUN MIX_ENV=prod mix do deps.get, deps.compile
COPY . .
RUN MIX_ENV=prod mix do compile, phx.digest

# Generar el release
RUN MIX_ENV=prod mix release

# Verificar la estructura del release
RUN ls -la /opt/app/_build/prod/rel/mono_app || echo "El release no se generó correctamente."
RUN ls -la /opt/app/_build/prod/rel/mono_app/bin/ || echo "El directorio 'bin' no fue generado."

# Etapa 3: Imagen Final para Producción
FROM debian:bookworm-slim AS app
ENV PORT=4000 LANG=C.UTF-8 REPLACE_OS_VARS=true PHX_SERVER=true
RUN apt-get update && apt-get install -y --no-install-recommends openssl libstdc++6 libc6 ncurses-base ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/app

# Copiar el release generado desde la etapa anterior
COPY --from=phx-builder /opt/app/_build/prod/rel/mono_app ./

# Verificar que el release fue copiado correctamente
RUN ls -la /opt/app/ || echo "Directorio /opt/app vacío o incompleto."
RUN ls -la /opt/app/config/ || echo "Directorio /opt/app/config/ vacío o incompleto."
RUN cat /opt/app/mix.exs || echo "mix.exs no encontrado o vacío."
RUN ls -la /opt/app/bin/ || echo "El directorio 'bin' no fue copiado correctamente."

# Crear un usuario no root y cambiar la propiedad de los archivos
RUN useradd -ms /bin/bash app && chown -R app:app /opt/app
USER app
EXPOSE 4000

# Comando para iniciar la aplicación
CMD ["bin/mono_app", "start"]
