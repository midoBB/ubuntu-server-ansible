# Ansible Role : ubuntu-pro

An Ansible Role that registers and configures host with [Ubuntu Pro](https://ubuntu.com/pro).

## Requirements

This role uses [Role Argument Validation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#role-argument-validation) introduced with **Ansible 2.11**.

Ubuntu Pro is only available for every **Ubuntu LTS releases from 16.04 LTS**.

## Roles Variables

The only mandatory variable is `ubuntu_pro_token`.

| Variable                                   | Description                      | Type   | Mandatory | Default Value |
|--------------------------------------------|----------------------------------|--------|-----------|---------------|
| `ubuntu_pro_token`                         | Ubuntu Pro token                 | String | YES       | None          |
||||||
| `ubuntu_pro_config.http_proxy`             | HTTP Proxy                       | String | NO        | None          |
| `ubuntu_pro_config.http_proxy`             | HTTPS Proxy                      | String | NO        | None          |
| `ubuntu_pro_config.apt_http_proxy`         | APT HTTP Proxy                   | String | NO        | None          |
| `ubuntu_pro_config.apt_https_proxy`        | APT HTTPS Proxy                  | String | NO        | None          |
| `ubuntu_pro_config.ua_apt_http_proxy`      | UA APT HTTP Proxy                | String | NO        | None          |
| `ubuntu_pro_config.ua_apt_https_proxy`     | UA APT HTTPS Proxy               | String | NO        | None          |
| `ubuntu_pro_config.global_apt_http_proxy`  | Global APT HTTP Proxy            | String | NO        | None          |
| `ubuntu_pro_config.global_apt_https_proxy` | Global APT HTTPS Proxy           | String | NO        | None          |
| `ubuntu_pro_config.update_messaging_timer` | Update Messaging Timer           | Int    | NO        | `21600`       |
| `ubuntu_pro_config.update_status_timer`    | Update Status Timer              | Int    | NO        | `43200`       |
| `ubuntu_pro_config.metering_timer`         | Metering Timer                   | Int    | NO        | `43200`       |

You can find more information about `ubuntu_pro_config.*` variables on [Ubuntu Pro Client README](https://github.com/canonical/ubuntu-advantage-client#readme).

Additional variables not related to ubuntu_pro_config:

- `ubuntu_pro_debug`: [default: `false`]: Show stdout and stderr for the pro commands
- `ubuntu_pro_state `: [default: `present`]: State for ubuntu pro, possible states are present, absent, attached and detached
- `ubuntu_pro_enabled_services`: [optional]: List of services to enable, check the list below
- `ubuntu_pro_disabled_services`: [optional]: List of services to disable, check the list below

There are a lot of different services that ubuntu pro provides which can be enabled and disabled. See the list below for accepted services by this role, those can be used for `ubuntu_pro_disabled_services` as well as `ubuntu_pro_enabled_services`.

```
- 'anbox-cloud'  # Scalable Android in the cloud
- 'cc-eal'       # Common Criteria EAL2
- 'esm-apps'     # Expanded Security Maintenance for Applications
- 'esm-infra'    # Expanded Security Maintenance for Infrastructure
- 'fips'         # NIST-certified FIPS crypto packages
- 'fips-preview' # Preview of FIPS crypto packages undergoing certification with NIST
- 'fips-updates' # FIPS compliant crypto packages with stable security updates
- 'landscape'    # Management and administration tool for Ubuntu
- 'livepatch'    # Canonical Kernel Livepatch
- 'realtime-kernel'  # Ubuntu kernel with PREEMPT_RT patches integrated
- 'realtime-kernel.generic'  # Generic version of the RT kernel (default)
- 'realtime-kernel.intel-iotg'  # RT kernel optimized for Intel IOTG platform
- 'ros'          # Security Updates for the Robot Operating System
- 'ros-updates'  # All Updates for the Robot Operating System
- 'usg'          # Security compliance and audit tools
```
## Dependencies

None.

## Example Playbook
```
- hosts: ubuntu_machines
  vars: ubuntu_pro_token: 'token'
  roles:
    - ubuntu-pro

```

## License

MIT / BSD

## Author Information

This role was created in October 2022 by [Sebastien Thebert](https://github.com/sebthebert).

Updated by Christian Erb in December 2024.
