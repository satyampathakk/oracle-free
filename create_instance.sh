#!/bin/bash

# -------------------------
# Configuration
# -------------------------

RETRY_INTERVAL=20   # Seconds between retries
MAX_RETRIES=200     # Max attempts before giving up (you can increase or set to 0 for infinite)

# -------------------------
# Main Logic
# -------------------------

retry_count=0

# Initialize Terraform
terraform init -input=false || { echo "Terraform init failed."; exit 1; }

while true; do
    current_attempt=$((retry_count + 1))
    echo "=============================="
    echo "🌀 Attempt #$current_attempt to apply Terraform..."
    echo "=============================="

    terraform apply -auto-approve -input=false

    if [ $? -eq 0 ]; then
        echo "✅ Instance created successfully on attempt #$current_attempt!"
        break
    else
        echo "❌ Failed to create instance on attempt #$current_attempt."

        # Check if it's an 'out of capacity' error
        if grep -q "Out of capacity for shape" terraform.tfstate 2>/dev/null || \
           grep -q "Out of capacity" .terraform/terraform.tfstate.backup 2>/dev/null; then
            echo "⚠️ Capacity issue detected, retrying after ${RETRY_INTERVAL}s..."
        else
            echo "⚠️ Some other error occurred. Still retrying..."
        fi

        retry_count=$((retry_count + 1))
        if [ $MAX_RETRIES -gt 0 ] && [ $retry_count -ge $MAX_RETRIES ]; then
            echo "❌ Reached max retry limit. Exiting."
            exit 1
        fi

        sleep $RETRY_INTERVAL
    fi
done
