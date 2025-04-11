# Use an official R base image with R 4.4.1
FROM rocker/r-ver:4.4.1

# Install system dependencies required for Shiny, YAML, and Python
RUN apt-get update && apt-get install -y \
    software-properties-common \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    curl \
    gdebi-core \
    libpng-dev \
    mailutils \
    postfix \
    dnsutils \
    iputils-ping \
    && add-apt-repository ppa:deadsnakes/ppa && apt-get update && \
    apt-get install -y python3.10 python3.10-distutils python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get install -y postfix && \
    systemctl enable postfix

# Set up the Python 3.10 environment for reticulate
ENV RETICULATE_PYTHON=/usr/bin/python3.10

# Create the shiny user and group
RUN groupadd -r shiny && useradd -r -g shiny shiny

# Install R packages (Shiny, shinyjs, yaml, bslib, jsonlite, reticulate)
RUN R -e "install.packages(c('shiny', 'yaml', 'shinyjs', 'bslib', 'jsonlite', 'reticulate'))" 


# Install Python packages if needed
#RUN python3.10 -m pip install --no-cache-dir pandas numpy secure-smtplib email-validator yaml pathlib shutil
RUN python3.10 -m pip install --no-cache-dir pandas numpy PyYAML email-validator


# Create a directory for your app and the YAML files inside the container
RUN mkdir -p /srv/shiny-server/yaml_files
RUN mkdir -p /srv/shiny-server/www

# Copy the app's R code and files into the container
COPY ../app.R /srv/shiny-server/
COPY ../messaging.py /srv/shiny-server/
COPY ../input_file_to_mtx.py /srv/shiny-server/
COPY ../mtx_file_check.py /srv/shiny-server/
COPY ../www/fig1.png /srv/shiny-server/www/
COPY ../www/fig2.png /srv/shiny-server/www/
COPY ../www/fig3.png /srv/shiny-server/www/
COPY ../www/sample_txt.txt /srv/shiny-server/www/
COPY ../www/omegasync_logo.png /srv/shiny-server/www/

# Set correct permissions for the directory and ensure 'shiny' user has write access
RUN chmod -R 777 /srv/shiny-server/yaml_files && chown -R shiny:shiny /srv/shiny-server/yaml_files
RUN chmod -R 777 /srv/shiny-server/* 
# Set the working directory for the Shiny app
WORKDIR /srv/shiny-server

# Expose the port on which Shiny will run
EXPOSE 3838

# Run the Shiny app, listen on all interfaces and set the port to 3838
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', host = '0.0.0.0', port = 3838)"]