#Version: 0.1.2
# Freely usable under the GPL license

FROM ubuntu:16.04
LABEL maintainer "Neoxian"

RUN apt-get update

# some tools I like

RUN apt-get -y install vim
RUN apt-get -y install curl
RUN apt-get -y install git 

# grab steemit.com

WORKDIR "/root"

RUN git clone https://github.com/steemit/steemit.com

WORKDIR "/root/steemit.com"

RUN git checkout 0.1.161221 

# the uncensored patch! #######################

#ADD uncensored_patch.txt /root/steemit.com/uncensored_patch.txt

#WORKDIR "/root/steemit.com"

#RUN git apply -v uncensored_patch.txt

#######################################################
 

EXPOSE 3001 3002 3301 3306

WORKDIR "/root/steemit.com"

RUN mkdir tmp

RUN apt-get -y install nodejs
RUN apt-get -y install npm
RUN apt-get -y install build-essential libssl-dev

WORKDIR "/root"

RUN curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh -o install_nvm.sh

RUN bash install_nvm.sh

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

WORKDIR "/root/steemit.com"

RUN source /root/.nvm/nvm.sh \
    && nvm install v6 \
    && npm install \
    && npm install -g babel-cli


WORKDIR "/root/steemit.com/config"

RUN cp steem-example.json steem-dev.json
RUN debconf-set-selections <<< 'mysql-server mysql-server/root_password password bob'
RUN debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password bob'
RUN apt-get -y install mysql-server

RUN service mysql start; mysql -u root --password=bob -e "create database steemit_dev;DROP USER 'root'@'localhost';CREATE USER 'root'@'%' IDENTIFIED BY '';GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';FLUSH PRIVILEGES;"

RUN npm install -g sequelize sequelize-cli pm2 mysql

WORKDIR "/root/steemit.com/db"

RUN source /root/.nvm/nvm.sh \
    && service mysql start \
    && sequelize db:migrate 

WORKDIR "/root/steemit.com/config"

RUN source /root/.nvm/nvm.sh \
    && node -p "crypto.randomBytes(32).toString('base64')" > key.txt

RUN sed -ie "s#somelongsecretstring#$(cat key.txt)#g" steem-dev.json

RUN apt-get -y install tarantool

