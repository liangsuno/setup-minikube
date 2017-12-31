
##########################################
# Lifecycle
##########################################

# install stage will install the software and bring it live
install: prepare

# prepare stage is to setup all the necessary basic software or configurations 
# required for the next stage >> install
prepare: setup-docker setup-minikube

##########################################
# Commands
##########################################

SHELL:=/bin/bash
OS := $(shell lsb_release -si)
OS_VERSION := $(shell lsb_release -sr)
ANSIBLE_INSTALLED := $(shell [ -f /usr/bin/ansible ] && echo true)

os:
	$(info Performing System check ...)
	$(info Detected OS=$(OS) version=$(OS_VERSION))
        ifeq ($(ANSIBLE_INSTALLED),true)
		$(info Detected ansible is already installed)
        else
		$(info Detected ansible is NOT installed)
        endif
	$(info System check completed.)

install-ansible:
        ifeq ($(OS),Ubuntu)
                ifeq ($(ANSIBLE_INSTALLED),true)
			$(info Ansible is already installed. Nothing to do here. Run "dpkg -l ansible" to check the version of Ansible installed)
                else
			sudo apt-get update
			sudo apt-get install -y software-properties-common
			sudo apt-add-repository -y ppa:ansible/ansible
			sudo apt-get update
			sudo apt-get install ansible
                endif
        else
		[ -f /usr/bin/ansible ] || sudo yum install ansible
        endif

setup-ansible: os install-ansible ansible-ping

ping: ansible-ping
ansible-ping:
	$(info Performing ansible ping check ...)
	ansible all -i hosts -m ping

setup-docker: setup-ansible
	service docker status >/dev/null || ansible-galaxy install -r requirements.yml
	service docker status >/dev/null || sudo ansible-playbook -i hosts setup-docker.yml
	sudo usermod -a -G docker ${USER}

setup-docker-force: setup-ansible
	ansible-galaxy install -r requirements.yml
	sudo ansible-playbook -i hosts setup-docker.yml
	sudo usermod -a -G docker ${USER}

setup-kubectl: setup-ansible
	ansible-galaxy install -r requirements.yml
	sudo ansible-playbook -i hosts setup-kubectl.yml

setup-minikube: setup-kubectl
	ansible-galaxy install -r requirements.yml
	sudo ansible-playbook -i hosts minikube.yml --tags setup

startup-minikube:
	ansible-galaxy install -r requirements.yml
	ansible-playbook -i hosts minikube.yml --tags startup
