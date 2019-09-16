FROM hashicorp/terraform
RUN mkdir -p /terraform-work
WORKDIR /terraform-work
VOLUME /terraform-work
