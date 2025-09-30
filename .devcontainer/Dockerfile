FROM python:3.13-bookworm

# Install kubectl (following https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm (from https://helm.sh/docs/intro/install/)
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

COPY . /workshop_exercise

WORKDIR /workshop_exercise

