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
