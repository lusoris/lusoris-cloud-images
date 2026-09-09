# Public & Private Cloud Generic Deployment Guide

`lusoris-cloud-images` images are multi-cloud portable and support all major public and private cloud environments out of the box.

## Supported Cloud Environments

Cloud-init is unconstrained and dynamically detects your hosting cloud provider:

- **OpenStack / Harvester**: Native `ConfigDrive` and OpenStack metadata service.
- **Amazon Web Services (AWS)**: EC2 IMDSv2 metadata service.
- **Google Cloud Platform (GCP)**: Compute Engine metadata service.
- **Microsoft Azure**: Azure metadata service.
- **Hetzner Cloud**: Hetzner Cloud metadata service.
- **Scaleway / DigitalOcean**: Standard cloud-init metadata interfaces.

## Launching on OpenStack via Glance

```bash
openstack image create "lusoris-base-generic" \
  --file lusoris-cloud-base-generic.qcow2 \
  --disk-format qcow2 \
  --container-format bare \
  --public
```
