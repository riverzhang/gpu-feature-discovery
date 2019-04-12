#!/bin/bash

set -xe

install_docker() {
	curl https://get.docker.com | sh
}

install_kubeadm() {
	apt-get update && apt-get install -y apt-transport-https curl
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
	apt-get update
	apt-get install -y kubelet kubeadm kubectl
	kubeadm init --pod-network-cidr=192.168.0.0/16
	mkdir -p /home/ubuntu/.kube
	cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
	chown ubuntu:ubuntu /home/ubuntu/.kube/config
	kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
	kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
	kubectl taint nodes --all node-role.kubernetes.io/master-
}

install_container_driver() {
	curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
	distribution="$(. /etc/os-release;echo $ID$VERSION_ID)"
	curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" | \
		tee /etc/apt/sources.list.d/nvidia-docker.list
	apt-get update && apt-get install -y nvidia-docker2
	sed -i 's/^#root/root/' /etc/nvidia-container-runtime/config.toml
	modprobe ipmi_msghandler
	modprobe i2c_core
	# Remove once https://gitlab.com/nvidia/driver/merge_requests/9 is merged
	git clone --single-branch --branch ubuntu18.04 https://gitlab.com/nvidia/driver
	docker build -t driver --build-arg DRIVER_VERSION=418.40.04 --build-arg KERNEL_VERSION=aws driver
	docker run -d --privileged --pid=host -v /run/nvidia:/run/nvidia:shared driver
}

install_driver() {
	add-apt-repository -y ppa:graphics-drivers/ppa
	apt update
	apt install -y ubuntu-drivers-common
	ubuntu-drivers autoinstall
}

install_nvidia_runtime() {
	curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
	distribution="$(. /etc/os-release;echo $ID$VERSION_ID)"
	curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" | \
		tee /etc/apt/sources.list.d/nvidia-docker.list
	apt-get update
	apt-get install -y nvidia-docker2
	cp daemon.json /etc/docker/daemon.json
	pkill -SIGHUP dockerd
	kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/1.0.0-beta/nvidia-device-plugin.yml
}

install_docker
install_container_driver
install_kubeadm
install_nvidia_runtime
usermod -a -G docker ubuntu
docker run -d -p 5000:5000 --name registry registry:2
