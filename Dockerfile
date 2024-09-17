# Etapa 1: Construcción de la aplicación
FROM elixir:1.17.2-slim AS build

# Establecer variables de entorno para evitar diálogos interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar el sistema e instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos mix para instalar dependencias
COPY mix.exs mix.lock ./

# Instalar Hex y Rebar sin verificación de repositorios
RUN mix local.hex --force && mix local.rebar --force

# Instalar las dependencias del proyecto
RUN MIX_ENV=prod mix deps.get

# Copiar el código de la aplicación
COPY . .

# Compilar la aplicación para producción
RUN MIX_ENV=prod mix compile

# Manejo de assets (JavaScript, CSS)
WORKDIR /app/assets
RUN npm install
RUN npm run build

# Volver al directorio de la aplicación
WORKDIR /app

# Generar los archivos estáticos de Phoenix
RUN MIX_ENV=prod mix phx.digest

# Generar el release de la aplicación incluyendo ERTS
RUN MIX_ENV=prod mix release --no-tar --include-erts

# Etapa 2: Imagen para producción
FROM debian:bullseye-slim AS app

# Establecer variables de entorno para evitar diálogos interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias necesarias para ejecutar la aplicación
RUN apt-get update && apt-get install -y \
    openssl \
    bash \
    libncurses5 \
    locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurar locale
ENV LANG=C.UTF-8

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el release generado en la etapa anterior
COPY --from=build /app/_build/prod/rel/mono_app ./

# Exponer el puerto donde Phoenix escuchará
EXPOSE 4000

# Ejecutar migraciones al iniciar el contenedor y luego iniciar la aplicación
CMD ["sh", "-c", "./bin/mono_app eval \"MonoApp.Release.migrate\" && ./bin/mono_app start"]
