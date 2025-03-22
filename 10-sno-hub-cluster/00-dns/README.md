# DNS Provider Configuration

This directory contains the configuration for the DNS provider using FreeIPA.

## Environment Variables

To securely provide the password for the FreeIPA provider, set the following environment variable before running Terraform:

```bash
export TF_VAR_freeipa_password="your_password_here"
```

Replace `your_password_here` with the actual password.

Ensure that this environment variable is set in your shell session or in a secure environment management tool before executing Terraform commands.
