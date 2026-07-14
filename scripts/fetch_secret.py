#!/usr/bin/env python3
import sys
import json
import requests
import urllib.parse

# Suppress noisy SSL verification warnings in the Terraform CLI output
requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

def main():
    try:
        params = json.loads(sys.stdin.read())
    except Exception as e:
        sys.stderr.write(f"JSON Parsing Error from Terraform stdin: {str(e)}\n")
        sys.exit(1)
        
    url = params["cyberark_url"].rstrip("/")
    username = params["cyberark_username"]
    password = params["cyberark_password"]
    safe = params["cyberark_safe"]
    account_name = params["cyberark_account_name"]
    validate_certs = params.get("validate_certs", "false").lower() == "true"

    session = requests.Session()
    token = None

    # Step 1: Authenticate Session
    auth_url = f"{url}/PasswordVault/API/auth/Cyberark/Logon"
    auth_payload = {"username": username, "password": password}
    
    try:
        response = session.post(auth_url, json=auth_payload, timeout=15, verify=validate_certs)
        response.raise_for_status()
        
        # Handle variations in token response format (string vs dict object)
        logon_data = response.json()
        if isinstance(logon_data, dict):
            token = logon_data.get("token") or logon_data.get("CyberArkLogonResult")
        else:
            token = str(logon_data).strip('"')
            
    except requests.exceptions.HTTPError as e:
        sys.stderr.write(f"CyberArk Authentication Failed: HTTP Error {e.response.status_code}\n")
        sys.exit(1)
    except Exception as e:
        sys.stderr.write(f"CyberArk Connection Failed: {str(e)}\n")
        sys.exit(1)

    if not token:
        sys.stderr.write("CyberArk Lookup Error: Auth token could not be parsed from response.\n")
        sys.exit(1)

    headers = {
        "Authorization": token,
        "Content-Type": "application/json"
    }

    try:
        # Step 2: Search for accounts using 'safeName'
        search_url = f"{url}/PasswordVault/API/Accounts?safeName={urllib.parse.quote(safe)}"
        acc_res = session.get(search_url, headers=headers, verify=validate_certs)
        acc_res.raise_for_status()
        accounts = acc_res.json().get('value', [])

        # Step 3: Isolate target account object
        target_account = None
        for account in accounts:
            if account.get('userName') == account_name or account.get('name') == account_name:
                target_account = account
                break
        
        if not target_account:
            for account in accounts:
                if account_name in account.get('name', ''):
                    target_account = account
                    break

        if not target_account:
            sys.stderr.write(f"CyberArk Filter Error: Account object matching '{account_name}' not found in Safe '{safe}'.\n")
            sys.exit(1)

        # Step 4: Retrieve the cleartext password string
        acc_id = target_account.get('id')
        pass_url = f"{url}/PasswordVault/API/Accounts/{acc_id}/Password/Retrieve"
        body = {"Reason": "Terraform Automation VMWare Provisioning"}

        p_res = session.post(pass_url, headers=headers, json=body, verify=validate_certs)
        p_res.raise_for_status()
        secret_value = p_res.json()

        # Step 5: Return payload back to Terraform engine core
        print(json.dumps({"secret": secret_value}))

    except Exception as e:
        sys.stderr.write(f"CyberArk Account Data Extraction Error: {str(e)}\n")
        sys.exit(1)
        
    finally:
        # Step 6: Explicitly log off immediately to free up the session slot
        try:
            if token:
                session.post(f"{url}/PasswordVault/API/auth/Logoff", headers=headers, verify=validate_certs)
        except Exception:
            pass

if __name__ == "__main__":
    main()

