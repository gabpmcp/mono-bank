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
FROM elixir:1.15.0 AS phx-builder

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

# Etapa 3: Imagen Final para Producción
FROM elixir:1.15.0-slim as app

# Exponer el puerto de la aplicación
EXPOSE 4000

# Configurar variables de entorno
ENV PORT=4000 \
    MIX_ENV=prod \
    LANG=C.UTF-8

# Instalar dependencias de runtime necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar los artefactos compilados desde la etapa de construcción
COPY --from=phx-builder /opt/app/_build /opt/app/_build
COPY --from=phx-builder /opt/app/priv /opt/app/priv
COPY --from=phx-builder /opt/app/config /opt/app/config
COPY --from=phx-builder /opt/app/lib /opt/app/lib
COPY --from=phx-builder /opt/app/deps /opt/app/deps
COPY --from=phx-builder /opt/app/mix.* /opt/app/

# Definir el usuario por defecto
USER default

# Comando para iniciar la aplicación
CMD ["mix", "phx.server"]
