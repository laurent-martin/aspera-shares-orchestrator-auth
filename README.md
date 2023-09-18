# Authorize a shares user based on IP address using Orchestrator

This project allows activation of an additional step for user authorization based on user's IP address.

This additional authorization is activated only for non-SAML users.

## Applying the patch for Shares directly

After repo cloning, type:

```bash
make
```

This will create the file: `private/config.sh`

Edit the file `private/config.sh`, and set your values, including:

- Orchestrator base URL, including the path. (e.g. `https://orchestrator.example.com/aspera/orchestrator`)
- Orchestrator User name
- Orchestrator Password
- Orchestrator Workflow ID for authorization
- Shares address (e.g. `shares.example.com`)
- an optional list of SAML domain name (e.g. `example.com`)

It is assumed that the current user has `ssh` access to the Shares server, and `sudo` access on it too.

To deploy on the Shares server, type:

```bash
make shares_deploy
```

This will generate the JSON config file and transfer the necessary files to the Shares server, and apply the patch.

To create the pre-populated patch, type:

```bash
make shares_pack
```

## Creating template patch

To create a template patch, type:

```bash
make shares_pack_tmpl
```

This creates the file: `generated/shares_patch_tmpl.tar.gz` which can be transferred on the Shares server.

## Applying the patch on Shares server

Get the file: `shares_patch_tmpl.tar.gz` on the Shares server, and extract it, it will provide those files:

- special_shares_auth.rb : The Ruby script which calls Orchestrator
- special_shares_auth.json.tmpl : The JSON configuration with Orchestrator credentials
- shares_patch.rb : The patch for Shares login function
- shares_patch.sh : The script which installs the patch

Rename the file `special_shares_auth.json.tmpl` to `special_shares_auth.json`, and edit it to set your values.

Then execute:

```bash
sudo ./shares_patch.sh apply
```

This will patch Shares and restart it, wait a few seconds.

To remove the patch:

```bash
sudo ./shares_patch.sh revert
```
