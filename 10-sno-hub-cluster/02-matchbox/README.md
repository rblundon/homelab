# Configure the OpenShift Agent Installer and Matchbox

## Create OpenShift Installation Files

<https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/epub/installing_an_on-premise_cluster_with_the_agent-based_installer/prepare-pxe-assets-agent#prepare-pxe-assets-agent>

### Downloading the Agent-based Installer

### Create/Modify config files

- agent-config.yaml
- install-config.yaml

### Run image creation

```bash
openshift-install agent create pxe-files
```

Recap of install in .openshift_install.log
