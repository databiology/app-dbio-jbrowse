FROM app/dbio/base:4.2.3

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update --fix-missing
RUN apt-get --no-install-recommends -qqy install \
        build-essential \
        python \
        zlib1g-dev \
        libxml2-dev \
        libexpat-dev \
        postgresql-client \
        wget \
        unzip \
        libpq-dev \
        locales \
        tabix \
        vcftools \
        samtools && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && \
    apt-get install git -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /www/html
COPY JBrowse-1.12.1.zip /www/html/
RUN cd /www/html && \
    unzip JBrowse-1.12.1.zip && \
    rm JBrowse-1.12.1.zip && \
    ln -s JBrowse-1.12.1 jbrowse

WORKDIR /www/html/jbrowse/
RUN ./setup.sh \
 && rm -rf /root/.cpan/

RUN perl Makefile.PL && make && make install

# Creating folder structure
RUN mkdir /www/html/jbrowse/data && chmod a+rwx /www/html/jbrowse/data

COPY wait.html /www/html/jbrowse/wait.html
RUN mv /www/html/jbrowse/index.html /www/html/jbrowse/main.html && \
    chmod 664 /www/html/jbrowse/wait.html

COPY jbrowse.conf /www/html/jbrowse/jbrowse.conf

RUN cd /www/html/jbrowse/plugins && \
    git clone https://github.com/bhofmei/jbplugin-methylation.git MethylationPlugin && \
    git clone https://github.com/bhofmei/jbplugin-smallrna.git SmallRNAPlugin

RUN mkdir -p /www/html/jbrowse/data/tracks/

COPY main.sh /usr/local/bin
RUN chmod +x /usr/local/bin/main.sh

COPY server.py /www/html/jbrowse/serve
RUN chmod +x /www/html/jbrowse/serve

WORKDIR /

EXPOSE 8000

COPY vcfmerger.sh /usr/local/bin/vcfmerger.sh
RUN chmod +x /usr/local/bin/vcfmerger.sh


