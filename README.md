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
Add this entry to /etc/docker/daemon.conf:

```
{ 
    "default-address-pools": [
         {"base":"10.10.0.0/16","size":24}
     ] 
}
```

and restart the docker daemon: `sudo service docker restart`

### Install Kerio VPN on Ubuntu
1. Install the software: `dpkg -i kerio-control-vpnclient_9.2.9.3171-1_amd64.deb`
2. Get the TOTP_CONTROL cookie from your machine. [Use this HOW-TO guide](https://confluence.devfactory.com/display/ISK/How+to+set+up+2FA+for+Kerio+VPN+via+Command+Line)
3. Replace the TOTP_CONTROL cookie in (kerio-kvc.service).
4. Copy (kerio-kvc.service) to `/lib/systemd/system/kerio-kvc.service`
5. Enable the VPN service to start automatically: `sudo systemctl enable kerio-kvc`
6. Start the VPN: `sudo systemctl start kerio-kvc`
