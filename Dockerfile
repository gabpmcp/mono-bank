# Etapa 1: Construcción de Assets (Frontend) usando una imagen de Node.js compatible
FROM node:18-bullseye AS assets-builder

# Establecer el directorio de trabajo
WORKDIR /app/assets

# Copiar solo package.json para aprovechar la caché de Docker
COPY assets/package.json ./

# Limpiar la caché de npm para evitar posibles conflictos
RUN npm cache clean --force

# Instalar las dependencias de Node.js
RUN npm install --no-progress --verbose

# Verificar la instalación de esbuild
RUN npx esbuild --version

# Copiar el resto de los assets
COPY assets/ .

# Construir los assets frontend
RUN npm run build

# Etapa 2: Construcción de la Aplicación Elixir (Backend)
FROM elixir:1.17.2 AS phx-builder

# Establecer la variable de entorno MIX_ENV
ENV MIX_ENV=prod

# Establecer el directorio de trabajo
WORKDIR /opt/app

# Instalar Hex y Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copiar archivos de configuración de Elixir
COPY mix.exs mix.lock ./

# Instalar las dependencias de Elixir
RUN mix do deps.get, deps.compile

# Copiar el resto del código de la aplicación
COPY . .

# Compilar la aplicación y generar digests de assets
RUN mix do compile, phx.digest

# Generar el release
RUN mix release

# Verificar que el release se generó correctamente
RUN ls -la /opt/app/_build/prod/rel/mono_app || echo "El release no se generó correctamente."

# Etapa 3: Imagen Final para Producción
FROM debian:bullseye-slim AS app

# Configurar variables de entorno
ENV PORT=4000 \
    LANG=C.UTF-8 \
    REPLACE_OS_VARS=true

# Instalar dependencias de runtime necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    ncurses-base \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar el release desde la etapa de construcción
COPY --from=phx-builder /opt/app/_build/prod/rel/mono_app ./

# Crear un usuario no root y cambiar la propiedad de los archivos
RUN useradd -ms /bin/bash app && \
    chown -R app:app /app

USER app

EXPOSE 4000

# Comando para iniciar la aplicación
CMD ["bin/mono_app", "start"]
