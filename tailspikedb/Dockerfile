FROM rocker/shiny
RUN apt-get update && apt install -y ncbi-blast+-legacy libxml2
RUN  R -e "install.packages(c('shinythemes','dplyr','DT','plyr','XML'))"
EXPOSE 3839
