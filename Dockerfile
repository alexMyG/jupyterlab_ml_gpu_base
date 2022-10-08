FROM nvidia/cuda:11.6.2-cudnn8-runtime-ubuntu20.04

USER root

# Ubuntu packages
RUN apt-get update
ENV DEBIAN_FRONTEND=noninteractive

RUN apt install -y python3 python3-pip zsh wget
RUN python3 -m pip install --upgrade pip
RUN apt-get install -y python3-dev git curl nodejs

# git global configuration
RUN git config --global pull.rebase true
RUN git config --global rebase.autoStash true 

RUN pip install --upgrade jupyter
RUN pip install --upgrade jupyterlab
RUN pip install jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --user
RUN jupyter nbextensions_configurator enable --user
RUN jupyter nbextension enable collapsible_headings/main --user

RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 14.18.1
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH


RUN nodejs --version

### Jupyterlab extensions
RUN pip install --upgrade jupyterlab-git jupyterlab-quickopen aquirdturtle_collapsible_headings 
# Jupyterlab lsp
RUN jupyter lab build

# Environmental variables for wandb
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# General pip packages
RUN pip install --upgrade twine keyrings.alt pynvml fastgpu

# Add the user settings. These should be copied by child images to the user folders
ADD .jupyter/lab/user-settings /.jupyter/lab/user-settings

# Add ipython_config.py in /etc/ipython
RUN mkdir /etc/ipython

RUN echo "c.Completer.use_jedi = False" > /etc/ipython/ipython_config.py
#ADD ipython_config.py /etc/ipython

# Install Github CLI
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& apt update \
&& apt install gh -y


# INSTALL NODEjs from NodeSource
#RUN curl -s http://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
#RUN sh -c "echo deb http://deb.nodesource.com/node_12.x focal main > /etc/apt/sources.list.d/nodesource.list"
#RUN apt-get update
#RUN apt-get install -y nodejs

# INSTALL CUDNN8
RUN apt-get update && apt-get install -y --no-install-recommends --allow-change-held-packages\
    libcudnn8 fonts-powerline \
    && apt-mark hold libcudnn8

# UPDATE JUPYTERLAB to 3.x (plotly visualization and pre-built debugger are now supported) ipkykernel>=6 is required
RUN pip3 install --upgrade jupyterlab jupyterlab-git nbdime aquirdturtle_collapsible_headings jupyterlab_widgets jupyterlab-quickopen ipykernel

# JUPYTERLAB additional extension for CPU, Memory, GPU usage and new themes
RUN pip3 install jupyterlab_nvdashboard jupyterlab-logout jupyterlab-system-monitor jupyterlab-topbar \
                 jupyterlab_theme_hale jupyterlab_theme_solarized_dark nbresuse \
                 jupyter-lsp jupyterlab-drawio jupyter-dash jupyterlab_code_formatter black isort jupyterlab_latex \
                 xeus-python theme-darcula jupyterlab_materialdarker lckr-jupyterlab-variableinspector

# Building Node js from scratch. Long process!!
# RUN apt-get install -y git-core curl build-essential libssl-dev\
#  && git clone https://github.com/nodejs/node.git \
#  && cd node \
#  && ./configure \
#  && make -j\
#  && make install


RUN jupyter labextension install jupyterlab-chart-editor 


# Required for Dash 
RUN jupyter lab build 

RUN pip3 install scikit-learn fastgpu nbdev pandas transformers tensorflow-addons \
     tensorflow pymongo emoji python-dotenv plotly

RUN pip3 install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cu117

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.3/zsh-in-docker.sh)"

ENV SHELL=/bin/zsh

RUN sed -i '/^ZSH_THEME/c\ZSH_THEME="agnoster"' ~/.zshrc


EXPOSE 8888
WORKDIR /
CMD ["jupyter","lab","--ip=0.0.0.0","--port=8888","--no-browser","--allow-root","--ContentsManager.allow_hidden=True"]
