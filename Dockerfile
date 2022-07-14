#based on shakapark/Minecraft-Enigmatica2-Server 
#also on  Antopower/enigmatica2expert

FROM eclipse-temurin:8-alpine
#FROM amazoncorretto:8-alpine3.15-jre
#FROM amazoncorretto:8

ENV MOTD="Minecraft Server: Enigmatica2ExpertSkyblock"

#ENV VERSION=1.37
#ENV MAP=world
ENV DIFFICULTY=2
#ENV GAMEMODE=0
ENV MAXPLAYERS=8
#ENV PVP=true
#ENV VIEWDISTANCE=10
#ENV HARDCORE=false

RUN addgroup --gid 1234 minecraft
RUN adduser --disabled-password -h /home/minecraft/E2Esky -u 1234 -G minecraft -g "any_minecraft_user" minecraft

RUN apk update && apk upgrade
RUN apk add bash

#RUN yum update 

#Couldn't download Cursforge's server pack in command line, so Manually added one.
ADD Server.zip /home/minecraft/E2Esky/Server.zip

RUN cd /home && mkdir -p minecraft/E2Esky && cd minecraft/E2Esky && \
	unzip Server.zip &&\
	rm Server.zip
#RUN cd /home && mkdir -p minecraft/E2Esky && cd minecraft/E2Esky && \
#	gpg-zip Server.zip . &&\
#	rm Server.zip


ADD newsettings.cfg /home/minecraft/E2Esky/settings.cfg
ADD ServerInstall.sh /home/minecraft/E2Esky/ServerInstall.sh

RUN cd /home/minecraft/E2Esky && bash ServerInstall.sh

RUN	chown -R minecraft:minecraft home/minecraft/E2Esky && \
    chmod +x /home/minecraft/E2Esky/ServerStartLinux.sh &&\
	chown minecraft:minecraft /home/minecraft/E2Esky/ServerStartLinux.sh


RUN sed -i "/motd\s*=.*/ c motd=$MOTD" /home/minecraft/E2Esky/server.properties &&\
#sed -i "/level-name\s*=.*/ c level-name=$MAP" /home/minecraft/E2Esky/server.properties &&\
sed -i "/difficulty\s*=.*/ c difficulty=$DIFFICULTY" /home/minecraft/E2Esky/server.properties &&\
#sed -i "/gamemode\s*=.*/ c gamemode=$GAMEMODE" /home/minecraft/E2Esky/server.properties &&\
sed -i "/max-players\s*=.*/ c max-players=$MAXPLAYERS" /home/minecraft/E2Esky/server.properties &&\
#sed -i "/pvp\s*=.*/ c pvp=$PVP" /home/minecraft/E2Esky/server.properties &&\
#sed -i "/view-distance\s*=.*/ c view-distance=$VIEWDISTANCE" /home/minecraft/E2Esky/server.properties &&\
#sed -i "/hardcore\s*=.*/ c hardcore=$HARDCORE" /home/minecraft/E2Esky/server.properties &&\
echo ""


WORKDIR /home/minecraft/E2Esky
USER minecraft
EXPOSE 25565
VOLUME /home/minecraft/E2Esky

CMD ["bash","ServerStartLinux.sh"]