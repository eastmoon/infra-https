# Check out https://hub.docker.com/_/debian to select a new base image
FROM debian:buster-slim

# Install dotnet runtime
RUN apt-get update -y && apt-get install -y wget
RUN wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN \
    apt-get update -y && \
    apt-get install -y \
        aspnetcore-runtime-2.2
RUN rm packages-microsoft-prod.deb

# Create dotnet app directory

# Set to a non-root built-in user `dotnet`
RUN \
    groupadd -r dotnet && \
    useradd -r -g dotnet dotnet && \
    mkdir -p /home/dotnet && \
    chown dotnet:dotnet /home/dotnet && \
    chmod 777 /home/dotnet

USER dotnet

# Create app directory (with user `dotnet`)
RUN mkdir -p /home/dotnet/app

WORKDIR /home/dotnet/app

# Bundle app source code
COPY --chown=dotnet ./published .

# Bind to all network interfaces so that it can be mapped to the host OS
ENV HOST=0.0.0.0 PORT=5000

RUN mkdir -p /home/dotnet/log
RUN \
    echo "dotnet Main.dll >> /home/dotnet/log/app.log 2>&1 &" > docker-entrypoint.sh && \
    echo "tail -f /dev/null" >> docker-entrypoint.sh
EXPOSE ${PORT}
CMD [ "/bin/bash", "docker-entrypoint.sh"]
