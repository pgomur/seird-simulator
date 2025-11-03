FROM gcc:14.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    python3 \
    python3-venv \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install pFUnit
WORKDIR /tmp
RUN git clone https://github.com/Goddard-Fortran-Ecosystem/pFUnit.git && \
    cd pFUnit && \
    mkdir build && cd build && \
    FC=gfortran cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DSKIP_MPI=YES \
        -DSKIP_OPENMP=YES && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd / && rm -rf /tmp/pFUnit

# Create a virtual environment for FORD and other Python packages
RUN python3 -m venv /opt/ford-venv && \
    /opt/ford-venv/bin/pip install --upgrade pip && \
    /opt/ford-venv/bin/pip install ford

# Add venv to the PATH to use ford globally
ENV PATH="/opt/ford-venv/bin:$PATH"

# Configure working directory
WORKDIR /app

# Run FORD when starting the container and then open bash
CMD ["bash", "-c", "mkdir -p /app/data && ford ford.yml && exec bash"]


# docker exec -it seird_fortran bash
# make clean
# make run
# make test

# docker-compose build
# docker-compose up -d
# ford ford.yml

# make run ARGS="40 RK45 1000 20 5 0 0 0.6 0.25 0.12 0.015 1000 0.05 1.2 0.01 0.2 0.05 0.01"

# | Posición | Parámetro             | Valor ejemplo |
# | -------- | --------------------- | ------------- |
# | 1        | DAYS                  | 40            |
# | 2        | METHOD                | RK45          |
# | 3        | S0                    | 1000          |
# | 4        | E0                    | 20            |
# | 5        | I0                    | 5             |
# | 6        | R0                    | 0             |
# | 7        | D0                    | 0             |
# | 8        | BETA                  | 0.6           |
# | 9        | SIGMA                 | 0.25          |
# | 10       | GAMMA                 | 0.12          |
# | 11       | MU                    | 0.015         |
# | 12       | N (total población)   | 1000          |
# | 13       | VACCINATION_RATE      | 0.05          |
# | 14       | CONTACT_RATE          | 1.2           |
# | 15       | WANING_IMMUNITY_RATE  | 0.01          |
# | 16       | ASYMPTOMATIC_FRACTION | 0.2           |
# | 17       | HOSPITALIZATION_RATE  | 0.05          |
# | 18       | MORTALITY_RATE_SEVERE | 0.01          |


