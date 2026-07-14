# fetch_secret.py
import sys
import json
import urllib.request
import urllib.parse
import ssl

def main():
    # Parse incoming query parameters from Terraform
    params = json.loads(sys.stdin.read())
    
    url = params["cyberark_url"].rstrip("/")
    username = params["cyberark_username"]
    password = params["cyberark_password"]
    safe = params["cyberark_safe"]
    account_name = params["cyberark_account_name"]
    validate_certs = params.get("validate_certs", "false").lower() == "true"

    ctx = ssl.create_default_context()
    if not validate_certs:
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

    try:
        # Step 1: Authenticate Session
        logon_url = f"{url}/PasswordVault/API/auth/Logon"
        logon_data = json.dumps({"username": username, "password": password}).encode("utf-8")
        req_logon = urllib.request.Request(logon_url, data=logon_data, headers={"Content-Type": "application/json"})
        
        with urllib.request.urlopen(req_logon, context=ctx, timeout=15) as response:
            token = response.read().decode("utf-8").strip('"')

        # Step 2: Query Target Safe & Account Object
        accounts_url = f"{url}/PasswordVault/API/Accounts?safe={urllib.parse.quote(safe)}&search={urllib.parse.quote(account_name)}"
        req_accounts = urllib.request.Request(accounts_url, headers={
            "Authorization": token,
            "Content-Type": "application/json"
        })
        
        with urllib.request.urlopen(req_accounts, context=ctx, timeout=15) as response:
            accounts_data = json.loads(response.read().decode("utf-8"))
            
        secret_value = accounts_data["value"][0]["secret"]

        # Step 3: Stream back as map for Terraform data allocation
        print(json.dumps({"secret": secret_value}))

    except Exception as e:
        sys.stderr.write(f"CyberArk Execution Error for object '{account_name}': {str(e)}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
