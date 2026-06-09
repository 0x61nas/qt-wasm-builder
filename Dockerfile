FROM alpine:latest


ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV QT_VER=6.8.2
ENV QT_SPEC=wasm-emscripten


USER anas
ENV HOME=/home/anas USER=anas TERM=xterm LANG=en_US.utf8 GIT_TERMINAL_PROMPT=0
WORKDIR /home/anas
RUN /bin/sh -c set -x  \
    && sudo apt-get update  \
    && sudo apt-get -y install  libpcre2-16-0   qtchooser \
    && wget -q https://storage.googleapis.com/accupara_images/qt${QT_VER}.tar.gz \
    && tar -xvf qt${QT_VER}.tar.gz -C /usr/local/  && rm qt${QT_VER}.tar.gz \
    && qtchooser -install qt6 /usr/local/Qt-${QT_VER}/bin/qmake6  \
    && sudo mv ~/.config/qtchooser/qt6.conf /usr/share/qtchooser/qt6.conf \
    && sudo mkdir -p /usr/lib/$(uname -p)-linux-gnu/qt-default/qtchooser \
    && sudo ln -n /usr/share/qtchooser/qt6.conf /usr/lib/$(uname -p)-linux-gnu/qt-default/qtchooser/default.conf  \
    && sudo apt-get clean  && sudo rm -f /var/lib/apt/lists/*_dists_* # buildkit
RUN /bin/sh -c sudo apt-get update \
    && sudo apt-get install -y locales python3-pip pipx git curl \
    && sudo locale-gen en_US.UTF-8 # buildkit
RUN /bin/sh -c sudo pipx install aqtinstall # buildkit
RUN /bin/sh -c sudo mkdir -p /usr/local/Qt/6.8.2 # buildkit
RUN /bin/sh -c sudo mv /usr/local/Qt-6.8.2 /usr/local/Qt/6.8.2/gcc_64 # buildkit
RUN /bin/sh -c sudo /root/.local/bin/aqt install-qt all_os wasm 6.8.2 wasm_singlethread -O /usr/local/Qt -m qtcharts qtwebsockets # buildkito
RUN /bin/sh -c git clone https://github.com/emscripten-core/emsdk.git ~/emsdk &&     cd ~/emsdk &&     ./emsdk install 3.1.56 &&     ./emsdk activate 3.1.56 # buildkit
WORKDIR /app
RUN /bin/sh -c sudo apt-get clean &&     sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* # buildkit
