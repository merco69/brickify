from setuptools import setup, find_packages

setup(
    name="ai_service",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "fastapi>=0.68.0",
        "uvicorn>=0.15.0",
        "numpy>=1.24.0",
        "scipy>=1.10.0",
        "scikit-learn>=1.2.0",
        "torch>=2.0.0",
        "torchvision>=0.15.0",
        "open3d>=0.17.0",
        "trimesh>=3.9.0",
        "pymeshlab>=2022.2.post2",
        "pillow>=9.5.0",
        "tqdm>=4.65.0",
        "matplotlib>=3.7.0"
    ],
    python_requires=">=3.11",
) 