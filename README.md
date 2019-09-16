
# How to Run Terraform in Docker

### terraform docker use cases

A number of use cases lend themselves well to running terraform inside a docker container. These include

- running projects in Terraform 0.12 when your laptop has Terraform 0.11 installed
- dockerizing terraform so that Jenkins can run it without polluting it with Terraform binaries
- delivering to a colleague (a terraform codebase) has a higher chance of working than guessing what is in their environment
- Terraform local_exec may demand python, curl etc on the host environment - docker is perfect for this
- using docker volumes (and maybe volume drivers) to manage Terraform state if you don't want to use S3 or Dynamo DB

## Terraform Docker Example | Creating VPCs in AWS

Our example will use a simple **[terraform module in github that creates VPCs](https://github.com/devops4me/terraform-aws-vpc-network)**.

### Step 1 | git clone into docker volume

First we create a docker volume (called **`vol.tfstate`**) and add the terraform module code to it by way of an **alpine git** container.

```
docker volume create vol.tfstate
docker run --interactive \
           --tty         \
	   --rm          \
	   --volume vol.tfstate:/terraform-work \
	   alpine/git \
	   clone https://github.com/devops4me/terraform-aws-vpc-network /terraform-work
sudo ls -lah /var/lib/docker/volumes/vol.tfstate/_data
```

### Step 2 | extend the hashicorp/terraform docker image

For the **[official hashicorp/terraform docker image](https://hub.docker.com/r/hashicorp/terraform)** to write into our volume, we need to extend it to set the WORKDIR and VOLUME.

```
FROM hashicorp/terraform:light
RUN mkdir -p /terraform-work
WORKDIR /terraform-work
VOLUME /terraform-work
```

Put the above in a Dockerfile then issue this docker build command.

```
docker build --rm --no-cache --tag img.terraform .
```


### Step 3 | terraform init via docker

As our volume contains the terraform module code from git and we have built a terraform docker image called **img.terraform**, we are now ready to perform a terraform init.

```
docker run --interactive \
           --tty \
	   --rm \
	   --name vm.terraform \
	   --volume vol.tfstate:/terraform-work \
	   img.terraform init example
sudo ls -lah /var/lib/docker/volumes/vol.tfstate/_data
```

The directory listing **verifies** that our volume now contains a **`.terraform`** directory.


### Step 4 | terraform apply via docker

At last we can run the terraform apply. Provide a role arn if your organization works with roles alongside the other 3 AWS authentication keys.

```
docker run --interactive \
           --tty \
	   --rm \
	   --name vm.terraform \
	   --env AWS_DEFAULT_REGION=<<aws-region-key>> \
	   --env AWS_ACCESS_KEY_ID=<<aws-access-key>> \
	   --env AWS_SECRET_ACCESS_KEY=<<aws-secret-key>> \
	   --env TF_VAR_in_role_arn=<<aws-role-arn>> \
	   --volume vol.tfstate:/terraform-work \
	   img.terraform apply -auto-approve example
```
