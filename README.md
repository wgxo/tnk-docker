# The New Kayako Docker Environment

This repository contains scripts for setting up and deploying The New Kayako (TNK)

Just run `./setup_and_deploy_tnk.sh` and it should do everything automatically.

### Send emails from TNK

Update _config.shared.php_ with Sendgrid API credentials:

```
    /**
     * Sendgrid
     */
    'account.sendgrid.apikey'                    => 'APIKEY',
    'sendgrid.account.sendgrid_key_paid.apikey'  => 'APIKEY',
    'sendgrid.account.sendgrid_key_trial.apikey' => 'APIKEY',
    'sendgrid.account_name.trial'                => 'sendgrid_key_trial',
    'sendgrid.account_name.paid'                 => 'sendgrid_key_paid',
```

### Receive emails in TNK
Configure Dakiya https://github.com/trilogy-group/kayako-dakiya

### Fix docker-compose up error when Kerio VPN is running
Running the following shows the reserved networks from Kerio and from Docker:

```
$ route -n|grep 172
172.16.0.0      44.175.0.1      255.240.0.0     UG    1      0        0 kvnet
172.17.0.0      0.0.0.0         255.255.255.0   U     0      0        0 docker0
```

The fix is to add any unused network to the docker-compose.yml files:

```
networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 172.19.0.0/24

```

### Install Kerio VPN on Ubuntu
1. Install the software: `dpkg -i kerio-control-vpnclient_9.2.9.3171-1_amd64.deb`
2. Get the TOTP_CONTROL cookie from your machine. [Use this HOW-TO guide](https://confluence.devfactory.com/display/ISK/How+to+set+up+2FA+for+Kerio+VPN+via+Command+Line)
3. Replace the TOTP_CONTROL cookie in [kerio-kvc.service](kerio-kvc.service).
4. Copy [kerio-kvc.service](kerio-kvc.service) to `/lib/systemd/system/kerio-kvc.service`
5. Enable the VPN service to start automatically: `sudo systemctl enable kerio-kvc`
6. Start the VPN: `sudo systemctl start kerio-kvc`
