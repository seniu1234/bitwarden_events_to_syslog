#!/bin/bash

TOKEN_URL="https://your_bitwarden_url/identity/connect/token"
CLIENT_ID="CLIENT_ID"
CLIENT_SECRET="CLIENT_SECRET"
BITWARDEN_API_URL="https://your_bitwarden_url/api/public/events"
USER_API_URL="https://your_bitwarden_url/api/public/members"
LAST_DATE=""

# Get the token using clientCredentials
get_access_token() {
  TOKEN_RESPONSE=$(curl -k -s -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET")

  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

  echo "$ACCESS_TOKEN"
}

# Function to retrieve user's email address based on userId
get_user_email() {
  USER_RESPONSE=$(curl -s -k -X GET "$USER_API_URL" -H "Authorization: Bearer $ACCESS_TOKEN")
  USER_EMAIL=$(echo "$USER_RESPONSE" | jq -r --arg actingUserId "$1" '.data[] | select(.userId == $actingUserId) | .email')
  echo "$USER_EMAIL"
}

# Function to write the LAST_DATE value to a file
save_last_date() {
  echo "$LAST_DATE" > bitwarden_last_date.txt
}

# Check if the bitwarden_last_date.txt file exists and read the date from it
if [ -f "bitwarden_last_date.txt" ]; then
  LAST_DATE=$(cat bitwarden_last_date.txt)
fi

ACCESS_TOKEN=$(get_access_token)

while true; do
  # Retrieve events in JSON format including the start date
  if [ -z "$LAST_DATE" ]; then
    TODAY_DATE=$(date -u +'%Y-%m-%dT00:00:01.000Z')
    START_DATE="$TODAY_DATE"
  else
    LAST_DATE=$(date -u -d "$LAST_DATE + 0.01 seconds" +'%Y-%m-%dT%H:%M:%S.%NZ')
    START_DATE="$LAST_DATE"
  fi

  # Calculate end date - add 1 day to the start date
  END_DATE=$(date -u -d "$START_DATE + 1 day" +'%Y-%m-%dT%H:%M:%S.%NZ')

  EVENTS_JSON=$(curl -s -k -X 'GET' "$BITWARDEN_API_URL?start=$START_DATE&end=$END_DATE" -H 'accept: application/json' -H "Authorization: Bearer $ACCESS_TOKEN")

  if [ -z "$EVENTS_JSON" ]; then
    echo "Error retrieving events."
  else
    # Use jq to parse the JSON and exclude the initial value
    events=($(echo "$EVENTS_JSON" | jq -c '.data[]'))

    for event in "${events[@]}"; do
      # Get the actingUserId from the event
      actingUserId=$(echo "$event" | jq -r '.actingUserId')

      # Get the user's email address
      user_email=$(get_user_email "$actingUserId")

      if [ -n "$user_email" ]; then
        # Add an email address to the event
        event=$(echo "$event" | jq --arg email "$user_email" '. + {email: $email}' | jq -c .)

        # Remove the comma and starting bracket before adding to syslog
        SYSLOG_ENTRY="bitwarden_api: $event"
        echo "$SYSLOG_ENTRY"

        # Add the event to syslog
        logger "$SYSLOG_ENTRY"
      fi
    done

    # Get the date from the first event
    first_event=${events[0]}
    first_date=$(echo "$first_event" | jq -r '.date')

    if [ -n "$first_date" ]; then
      LAST_DATE="$first_date"
      save_last_date  # Save the LAST_DATE value to a file
    fi
  fi

  sleep 10
done