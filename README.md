# Authorize an Aspera Shares user based on IP address using Aspera Orchestrator

This project allows an additional step for user authorization based on user's IP address using Aspera Orchestrator.

This additional authorization is activated only for non-SAML users.

## Installation

1. Import the 2 workflows provided in Orchestrator,
2. Take a note of the identifier (integer) of the workflow "Check User Address"
3. Apply the patch to Shares as specified in the next section.

## Applying the patch on Shares server

### Creating the patch from repo

To create the patch archive, type:

```bash
make
```

This creates the file: `generated/shares_patch_tmpl.tar.gz` which can be transferred on the Shares server.

Else you may also get the 5 files listed below from the repository.

### Get the patch file

Transfer the file: `generated/shares_patch_tmpl.tar.gz` to the Shares server, and extract it, it will provide those files:

- `shares_patch.sh` : The script which installs the patch
- `special_shares_auth.rb` : The library that calls Aspera Orchestrator for the validation
- `special_shares_auth.json.tmpl` : The JSON configuration with Orchestrator credentials
- `shares_patch_api.rb` : Patch for the API control
- `shares_patch_login.rb`: Patch for web session control

Rename the file `special_shares_auth.json.tmpl` to `special_shares_auth.json`, and edit it to set your values.

Example:

```json
{
    "url": "https://orchestrator.example.com/aspera/orchestrator",
    "user": "orchestrator_user",
    "pass": "password_for_above",
    "workflow":"12345"
}
```

> **Note:** The workflow identifier is the numerical id (integer) of workflow: **Check User Address**

### Apply the patch

To apply the patch:

```bash
sudo ./shares_patch.sh apply
```

This will patch **Aspera Shares** and restart it, wait a minute for Shares to restart.

### Remove the patch

To remove the patch:

```bash
sudo ./shares_patch.sh revert
```

### Applying the patch remotely

Alternatively, if you are developing the patch:

After repo cloning, type:

```bash
make init
```

This will create the file: `private/config.sh`

Edit the file `private/config.sh`, and set your values, including:

- Orchestrator base URL, including the path. (e.g. `https://orchestrator.example.com/aspera/orchestrator`)
- Orchestrator User name
- Orchestrator Password
- Orchestrator Workflow ID for authorization
- Shares address (e.g. `shares.example.com`)

It is assumed that the current user has `ssh` access to the Shares server, and `sudo` access on it too.

To deploy on the Shares server, type:

```bash
make shares_deploy
```

This will generate the JSON config file and transfer the necessary files to the Shares server, and apply the patch.

## Workflows

Two Orchestrator workflows are provided:

- Check User Address : This is the runtime callback for Shares to check if a user is authorized
- Whitelist : This is the workflow that contains the whitelist, to be edited.
