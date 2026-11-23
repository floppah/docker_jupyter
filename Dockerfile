
ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_CONTAINER=$REGISTRY/$OWNER/scipy-notebook:latest
FROM $BASE_CONTAINER

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

USER $NB_UID

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change

RUN fix-permissions $CONDA_DIR && fix-permissions /home/$NB_USER

EXPOSE 8888
EXPOSE 8080
EXPOSE 3001
EXPOSE 3022

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

USER root

# install SSH and enable on port 3022
RUN apt update
RUN apt install openssh-server
RUN cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
RUN sed -i 's/^#\?Port .*/Port 3022/' /etc/ssh/sshd_config || echo 'Port 3022'
RUN tee -a /etc/ssh/sshd_config

RUN usermod -aG sudo jovyan
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# install nodejs
RUN apt install nodejs npm

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/start.sh
RUN chmod 777 /usr/local/bin/start-notebook.sh

COPY jupyter_notebook_config.py /etc/jupyter
RUN chmod 777 /etc/jupyter/jupyter_notebook_config.py

COPY opencode.json /home/jovyan/.config/opencode/opencode.json
RUN chmod -R 777 /home/jovyan/.config/

USER $NB_UID

# Opencode and Jupyter dependencies
RUN pip install jupyter-ai
RUN pip install jupyterlab-terminal-clipboard-extension
RUN curl -fsSL https://opencode.ai/v2/install | bash

# dynamic context protocol to prune unnecessary context
RUN opencode plugin add @tarquinen/opencode-dcp@latest
# Graphify to make opencode super smart
RUN pip install graphifyy
RUN graphify install --project --platform opencode
# Claude-mem to make opencode remember things like an elephant
RUN npx claude-mem install --ide opencode


WORKDIR $HOME
