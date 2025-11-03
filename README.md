# seird-simulator

<p>Epidemiological modeling system based on SEIRD differential equations with extensions for vaccination, immunity waning, asymptomatic fraction, hospitalization, and differential mortality. Modular architecture supporting individual and batch simulations parallelized with OpenMP, including prevention of division by zero, clipping of negative values, and error control in adaptive integrators.</p>

<p>Implements three numerical methods: explicit Euler, 4th-order Runge-Kutta (RK4), and Runge-Kutta-Fehlberg 4-5 (Dormand-Prince), adaptive and optimal for systems with variable or potentially stiff dynamics, with automatic step size adjustment and integration statistics.</p>

<p>Exports results to CSV with derived metrics (effective R₀, active population) and ASCII visualization.</p>

<p>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-7D9EC0?logo=github" /></a>
  <img src="https://img.shields.io/badge/Docker-Active-29ABE2?logo=docker" />
  <img src="https://img.shields.io/badge/Fortran-2023-F05032?logo=gnu" />
  <img src="https://img.shields.io/badge/GNU_Fortran-14.2.0-E95420?logo=gnu" />
  <img src="https://img.shields.io/badge/CMake-3.28.3-064F8C?logo=cmake" />
  <img src="https://img.shields.io/badge/HDF5-1.14.3-4393D3?logo=hdf5" />
</p>

<h2>📂 Project Structure</h2>

```text
seird-simulator/
│   CMakeLists.txt           # Build configuration for CMake
│   docker-compose.yml       # Docker Compose setup
│   Dockerfile               # Docker image build instructions
│   ford.yml                 # Project-specific configuration (custom)
│   LICENSE                  # License file
│   Makefile                 # Traditional build system
│   README.md                # Project README
│
├───build-cmake              # CMake build output directory (generated after build)
├───data                     # Output data for simulations (generated during runtime)
├───doc                      # Documentation files (generated)
├───src                      # Source code modules
│       io_mod.f90               # Input/Output module
│       main.f90                 # Main program
│       numerics_mod.f90         # Numerical methods module
│       parameters_mod.f90       # Model parameters module
│       precision_mod.f90        # Precision and numerical constants module
│       seird_model_mod.f90      # SEIRD model equations module
│       visualization_mod.f90    # Visualization module (ASCII)
│
└───test                     # Unit and integration tests
        test_io.pf                # Tests for I/O module
        test_main.pf              # Tests for main program
        test_numerics.pf          # Tests for numerical methods
        test_parameters.pf        # Tests for parameters module
        test_precision.pf         # Tests for precision module
        test_seird_model.pf       # Tests for SEIRD model module
        test_visualization.pf     # Tests for visualization module
```

<h2>⚙️ Installation &amp; Usage</h2>

<h3>🐳 Using Docker (recommended)</h3>

<pre><code># 1. Build the Docker image
docker-compose build

# 2. Start the container
docker-compose up -d
</code></pre>

<p>Access the running container:</p>

<pre><code>docker exec -it seird_fortran bash
</code></pre>

<p>Inside the container:</p>

<pre><code># Clean previous builds
make clean

# Run tests (unit + integration)
make test

# Run a simulation (example command)
make run ARGS="40 RK45 1000 20 5 0 0 0.6 0.25 0.12 0.015 1000 0.05 1.2 0.01 0.2 0.05 0.01"
</code></pre>

<p>Results are stored in <code>/app/data</code> (mapped to <code>./data</code> on the host).  
During execution, the program prints an ASCII visualization of compartment evolution and integration statistics.</p>

<hr />

<h3>🧩 Command-line Arguments</h3>

<p>The executable accepts <strong>18 positional arguments</strong> defining simulation time, numerical method, initial conditions, and epidemiological parameters.</p>

<table>
  <thead>
    <tr>
      <th style="text-align:right;">Position</th>
      <th>Parameter</th>
      <th>Example Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr><td style="text-align:right;">1</td><td><code>DAYS</code></td><td>40</td><td>Duration of the simulation in days</td></tr>
    <tr><td style="text-align:right;">2</td><td><code>METHOD</code></td><td>RK45</td><td>Numerical method (<code>EULER</code>, <code>RK4</code>, or <code>RK45</code>)</td></tr>
    <tr><td style="text-align:right;">3</td><td><code>S0</code></td><td>1000</td><td>Initial number of susceptible individuals</td></tr>
    <tr><td style="text-align:right;">4</td><td><code>E0</code></td><td>20</td><td>Initial number of exposed individuals</td></tr>
    <tr><td style="text-align:right;">5</td><td><code>I0</code></td><td>5</td><td>Initial number of infected individuals</td></tr>
    <tr><td style="text-align:right;">6</td><td><code>R0</code></td><td>0</td><td>Initial number of recovered individuals</td></tr>
    <tr><td style="text-align:right;">7</td><td><code>D0</code></td><td>0</td><td>Initial number of deceased individuals</td></tr>
    <tr><td style="text-align:right;">8</td><td><code>BETA</code></td><td>0.6</td><td>Transmission rate (probability of infection per contact)</td></tr>
    <tr><td style="text-align:right;">9</td><td><code>SIGMA</code></td><td>0.25</td><td>Incubation rate (1/incubation period)</td></tr>
    <tr><td style="text-align:right;">10</td><td><code>GAMMA</code></td><td>0.12</td><td>Recovery rate (1/infectious period)</td></tr>
    <tr><td style="text-align:right;">11</td><td><code>MU</code></td><td>0.015</td><td>Baseline mortality rate</td></tr>
    <tr><td style="text-align:right;">12</td><td><code>N</code></td><td>1000</td><td>Total population</td></tr>
    <tr><td style="text-align:right;">13</td><td><code>VACCINATION_RATE</code></td><td>0.05</td><td>Fraction of population vaccinated per day</td></tr>
    <tr><td style="text-align:right;">14</td><td><code>CONTACT_RATE</code></td><td>1.2</td><td>Average number of daily contacts per person</td></tr>
    <tr><td style="text-align:right;">15</td><td><code>WANING_IMMUNITY_RATE</code></td><td>0.01</td><td>Rate of immunity loss (vaccinated or recovered)</td></tr>
    <tr><td style="text-align:right;">16</td><td><code>ASYMPTOMATIC_FRACTION</code></td><td>0.2</td><td>Fraction of infected individuals that are asymptomatic</td></tr>
    <tr><td style="text-align:right;">17</td><td><code>HOSPITALIZATION_RATE</code></td><td>0.05</td><td>Fraction of symptomatic cases that require hospitalization</td></tr>
    <tr><td style="text-align:right;">18</td><td><code>MORTALITY_RATE_SEVERE</code></td><td>0.01</td><td>Mortality among hospitalized (severe) cases</td></tr>
  </tbody>
</table>

<hr />

<h3>📊 Output</h3>

<p><strong>CSV Output</strong> (stored in <code>./data/</code>):</p>

<pre><code>Day,Susceptibles,Expuestos,Infectados,Recuperados,Muertos,Vacunacion,Activos,RatioInfectados,ContactRate,WaningImmunity
</code></pre>

<p>Includes derived metrics such as <em>effective R₀</em> and <em>active population fraction</em>.</p>

<p><strong>Terminal Output:</strong></p>
<ul>
  <li>ASCII time-series visualization of compartment evolution.</li>
  <li>Integration statistics (accepted/rejected steps, max error, step-size adaptation).</li>
</ul>

<p><strong>Documentation:</strong></p>
<ul>
  <li>Automatically generated by <code>FORD</code> at container startup → stored in <code>/app/doc</code> (or <code>./doc/</code> on the host).</li>
</ul>
