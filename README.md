# bitwarden_event_to_syslog

The `bitwarden_events_to_syslog.sh` script is a tool for monitoring Bitwarden events using the Bitwarden API and recording them in the syslog.
To make it easier to identify the user, an item with the user's email address has been added.

## Requirements

Before using this script, ensure that you have the following tools and libraries installed:

- `bash`
- `curl`
- `jq` (if available, it can be used for easier JSON processing)

## Configuration

Before running the `bitwarden_api_to_syslog3.sh` script, you need to customize the following configuration variables:

- `TOKEN_URL`: The URL to obtain an access token.
- `CLIENT_ID`: The client ID for authentication.
- `CLIENT_SECRET`: The client secret for authentication.
- `BITWARDEN_API_URL`: The Bitwarden API URL.
- `USER_API_URL`: The API URL for retrieving user email addresses.
- `LAST_DATE`: The default start date (optional - the script will automatically retrieve the date from the `bitwarden_last_date.txt` file).

## Usage

Run the script:
   
   ./bitwarden_events_to_syslog.sh
