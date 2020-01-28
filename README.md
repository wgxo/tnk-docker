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
