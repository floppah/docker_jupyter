
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
EXPOSE 8501

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

USER root

RUN usermod -aG sudo jovyan
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/start.sh
RUN chmod 777 /usr/local/bin/start-notebook.sh

COPY jupyter_notebook_config.py /etc/jupyter
RUN chmod 777 /etc/jupyter/jupyter_notebook_config.py

USER $NB_UID

WORKDIR $HOME
