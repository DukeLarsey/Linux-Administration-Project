#!/bin/bash

echo "----------------------------------------"
echo "        Employee Onboarding Portal"
echo "----------------------------------------"

# Define valid departments (must match existing system groups)
VALID_DEPARTMENTS=("management" "sales" "it" "marketing" "finance")

echo "Available departments: ${VALID_DEPARTMENTS[*]}"

# Prompt for employee name
read -p "Enter employee name: " fullname

# Validate name is not empty
if [ -z "$fullname" ]; then
    echo "Error: Name cannot be empty."
    exit 1
fi

# Prompt for department
read -p "Enter department: " department

# Normalize inputs
clean_name=$(echo "$fullname" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
clean_dept=$(echo "$department" | tr '[:upper:]' '[:lower:]')

# Validate department against allowed list
valid=false
for dept in "${VALID_DEPARTMENTS[@]}"; do
    if [ "$clean_dept" == "$dept" ]; then
        valid=true
        break
    fi
done

if [ "$valid" = false ]; then
    echo "Error: Invalid department."
    echo "Valid options are: ${VALID_DEPARTMENTS[*]}"
    exit 1
fi

# Verify group actually exists on system
if ! getent group "$clean_dept" > /dev/null; then
    echo "Error: Group '$clean_dept' does not exist on system."
    exit 1
fi

# Create username (department_name format)
username="${clean_dept}_${clean_name}"

echo "Generated username: $username"

# Check if user already exists
if id "$username" &>/dev/null; then
    echo "Error: User already exists."
    exit 1
fi

# Password input
read -s -p "Enter password: " password
echo
read -s -p "Confirm password: " confirm_password
echo

# Validate passwords
if [ -z "$password" ]; then
    echo "Error: Password cannot be empty."
    exit 1
fi

if [ "$password" != "$confirm_password" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

# Create user
sudo useradd -m -g "$clean_dept" "$username"

# Set password
echo "$username:$password" | sudo chpasswd

# Capture creation time
creation_time=$(date)

# Log action
sudo mkdir -p /company/logs
echo "$creation_time - Created user $username ($clean_dept)" | sudo tee -a /company/logs/onboarding.log > /dev/null

# Output summary
echo "----------------------------------------"
echo "        Employee Onboarding Summary"
echo "----------------------------------------"
echo "Full Name     : $fullname"
echo "Department    : $clean_dept"
echo "Username      : $username"
echo "Home Directory: /home/$username"
echo "Created At    : $creation_time"
echo "Status        : SUCCESS"
echo "----------------------------------------"