#!/bin/bash

# Installation des dépendances système
apt-get update && apt-get install -y \
    git \
    python3-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-glx

# Installation de PyTorch3D depuis le source
pip install 'git+https://github.com/facebookresearch/pytorch3d.git@stable'

# Installation des dépendances supplémentaires
pip install \
    trimesh \
    numpy \
    scipy \
    opencv-python \
    open3d \
    pymeshlab \
    meshio 