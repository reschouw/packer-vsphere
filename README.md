# packer-vsphere

This repo contains all the needed configuration to create a vSphere template that can be cloned and configured in an automated fashing using Terraform.

## Purpose
This started out as just a project to learn Packer after some coworkers were talking about how cool it is (It is indeed cool). It turned into part of the workflow I use to stand up new VMs in my homelab. 

The other half of this project can be found [here](https://github.com/reschouw/terraform-vsphere). 

## Overview
This project stands up a fresh Ubuntu 18.04 instance using Hashicorp's Packer. It's most important task is to install the prerequisites for using Terraform to pass cloud-init the code to automatically download my Ansible Repo and run a specified playbook (as well as taking care of all the networking config, hostnames, etc)

## Installation
If you're familiar with the basics of Packer and have it already installed, all that should be needed is for you to update the ubuntu.pkr.hcl file with your own information and run a packer build in the corresponding directory. 

Installation instructions for Packer can be found [here](https://learn.hashicorp.com/packer/getting-started/install).

## Lessons Learned

 - Packer is cool. The ability to get away from the "Golden Image" noone remembers how to troubleshoot or recreate is gone, and is replaced by beautiful infrastructure as code. 
 - The basics of just getting the image to boot using the preseed.cfg file was somewhat difficult. Luckily examples exist elsewhere on the internet I was able to draw from. 
 - The most difficult thing here was getting cloud init to play nice with vSphere. The two don't play nicely, as cloud-init actually disables the vsphere customization completely, and there isn't a built-in way for vSphere to even pass the cloud-init config. See ubuntu.pkr.hcl to find out how all this is circumvented.

### Author
Ryan Schouweiler
