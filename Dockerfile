FROM debian
MAINTAINER Alexander Volz (Alexander@volzit.de)

ENV SMVERSION 1.10

ENV _clean="rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
ENV _apt_clean="eval apt-get clean && $_clean"

# Install support pkgs
RUN apt-get update -qqy && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl wget nano net-tools gnupg2 git lib32stdc++6 python3 \
    python3-pip python3-setuptools tar bash  && $_apt_clean

ENV SMBUILDER_REPO https://github.com/mathiassmichno/sm-builder
RUN pip3 install --user git+${SMBUILDER_REPO}

RUN mkdir /get5
RUN mkdir /runscripts
RUN mkdir /get5src
COPY dockerrunscript.sh /runscripts
WORKDIR /get5

ENV SMPACKAGE http://sourcemod.net/latest.php?os=linux&version=${SMVERSION}
RUN wget -q ${SMPACKAGE}
RUN tar xfz $(basename ${SMPACKAGE})
RUN chmod +x /get5/addons/sourcemod/scripting/spcomp
ENV PATH "$PATH:/get5/addons/sourcemod/scripting:/root/.local/bin"
WORKDIR /get5/addons/sourcemod/scripting/include
ADD https://raw.githubusercontent.com/KyleSanderson/SteamWorks/master/Pawn/includes/SteamWorks.inc SteamWorks.inc
WORKDIR /get5

VOLUME /get5/builds
VOLUME /get5src
CMD ["/runscripts/dockerrunscript.sh"]
