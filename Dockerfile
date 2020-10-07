FROM debian:10
MAINTAINER Alexander Volz (Alexander@volzit.de)

ENV SMVERSION 1.10

ENV _clean="rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
ENV _apt_clean="eval apt-get clean && $_clean"

# Install support pkgs
RUN apt-get update -qqy && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl wget nano net-tools gnupg2 git lib32stdc++6 python3 \
    python3-pip tar bash  && $_apt_clean

COPY . /get5
WORKDIR /get5

RUN git submodule update --init

RUN git clone https://github.com/mathiassmichno/sm-builder
WORKDIR /get5/sm-builder
RUN pip3 install --user -r requirements.txt
RUN python3 setup.py install --prefix=~/.local
WORKDIR /get5

ENV SMPACKAGE http://sourcemod.net/latest.php?os=linux&version=${SMVERSION}
RUN wget -q ${SMPACKAGE}
RUN tar xfz $(basename ${SMPACKAGE})
RUN chmod +x /get5/addons/sourcemod/scripting/spcomp
ENV PATH "$PATH:/get5/addons/sourcemod/scripting:/root/.local/bin"
WORKDIR /get5/addons/sourcemod/scripting/include
ADD https://raw.githubusercontent.com/KyleSanderson/SteamWorks/master/Pawn/includes/SteamWorks.inc
ADD https://raw.githubusercontent.com/ErikMinekus/sm-ripext/master/pawn/scripting/include/ripext/http.inc
ADD https://github.com/ErikMinekus/sm-ripext/blob/master/pawn/scripting/include/ripext/json.inc
WORKDIR /get5

VOLUME /get5/builds
CMD ["smbuilder", "--flags='-E'"]
