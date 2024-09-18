# PowerShell script to register, authenticate, and send multiple generate requests concurrently

# Base API URL
$baseUrl = "http://3.27.244.114:8000"

# Endpoint URLs
$registerUrl = "$baseUrl/api/register"
$loginUrl = "$baseUrl/api/login"
$generateUrl = "$baseUrl/api/generate"

# Headers
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

# User credentials - define multiple users
$users = @(
    @{ "username" = "user1"; "password" = "pass1" },
    @{ "username" = "user2"; "password" = "pass2" },
    @{ "username" = "user3"; "password" = "pass3" }
)

# Number of requests to send per user
$request_count = 10

# Function to register and authenticate a user
function RegisterAndAuthenticate {
    param (
        [string]$username,
        [string]$password
    )

    # Registration body
    $registerBody = @{
        "username" = $username
        "password" = $password
    } | ConvertTo-Json

    # Step 1: Register the user
    try {
        $registerResponse = Invoke-RestMethod -Uri $registerUrl -Method Post -Headers $headers -Body $registerBody
        Write-Host "Registration successful for ${username}: $registerResponse"
    }
    catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 400) {
            Write-Host "User ${username} already exists, proceeding with login."
        } else {
            Write-Host "Registration failed for ${username}: $_"
            return
        }
    }

    # Step 2: Login to get a session_id
    $loginBody = @{
        "username" = $username
        "password" = $password
    } | ConvertTo-Json

    try {
        $loginResponse = Invoke-RestMethod -Uri $loginUrl -Method Post -Headers $headers -Body $loginBody
        $session_id = $loginResponse.session_id

        if (!$session_id) {
            Write-Host "Login failed or session_id not found for ${username}."
            return
        }

        Write-Host "Login successful for ${username}. Session ID: ${session_id}"

        # Prepare headers for the generate request
        $authHeaders = $headers.Clone()
        $authHeaders.Add("Authorization", "Bearer ${session_id}")

        # Step 3: Loop to send multiple generate requests
        for ($i = 1; $i -le $request_count; $i++) {
            Write-Host "Sending request #$i for ${username}"
            $generateBody = @{
                "user_id" = $username
                "prompt" = "Hello, how are you?"
            } | ConvertTo-Json

            try {
                $generateResponse = Invoke-RestMethod -Uri $generateUrl -Method Post -Headers $authHeaders -Body $generateBody
                Write-Host "Response from server for ${username}: $($generateResponse.response)"
            }
            catch {
                Write-Host "Request #$i for ${username} failed: $_"
            }

            Start-Sleep -Seconds 1 # Optional: Add delay between requests
        }
    }
    catch {
        Write-Host "Error during login for ${username}: $_"
    }
}

# Start parallel jobs for each user
foreach ($user in $users) {
    Start-Job -ScriptBlock {
        # Define the function within the job's script block
        function RegisterAndAuthenticate {
            param (
                [string]$username,
                [string]$password
            )

            $baseUrl = "http://3.27.244.114:8000"
            $registerUrl = "$baseUrl/api/register"
            $loginUrl = "$baseUrl/api/login"
            $generateUrl = "$baseUrl/api/generate"
            $headers = @{
                "Content-Type" = "application/json"
                "Accept" = "application/json"
            }

            # Registration body
            $registerBody = @{
                "username" = $username
                "password" = $password
            } | ConvertTo-Json

            # Step 1: Register the user
            try {
                $registerResponse = Invoke-RestMethod -Uri $registerUrl -Method Post -Headers $headers -Body $registerBody
                Write-Host "Registration successful for ${username}: $registerResponse"
            }
            catch {
                if ($_.Exception.Response.StatusCode.Value__ -eq 400) {
                    Write-Host "User ${username} already exists, proceeding with login."
                } else {
                    Write-Host "Registration failed for ${username}: $_"
                    return
                }
            }

            # Step 2: Login to get a session_id
            $loginBody = @{
                "username" = $username
                "password" = $password
            } | ConvertTo-Json

            try {
                $loginResponse = Invoke-RestMethod -Uri $loginUrl -Method Post -Headers $headers -Body $loginBody
                $session_id = $loginResponse.session_id

                if (!$session_id) {
                    Write-Host "Login failed or session_id not found for ${username}."
                    return
                }

                Write-Host "Login successful for ${username}. Session ID: ${session_id}"

                # Prepare headers for the generate request
                $authHeaders = $headers.Clone()
                $authHeaders.Add("Authorization", "Bearer ${session_id}")

                # Step 3: Loop to send multiple generate requests
                for ($i = 1; $i -le 10; $i++) {
                    Write-Host "Sending request #$i for ${username}"
                    $generateBody = @{
                        "user_id" = $username
                        "prompt" = "Hello, how are you?"
                    } | ConvertTo-Json

                    try {
                        $generateResponse = Invoke-RestMethod -Uri $generateUrl -Method Post -Headers $authHeaders -Body $generateBody
                        Write-Host "Response from server for ${username}: $($generateResponse.response)"
                    }
                    catch {
                        Write-Host "Request #$i for ${username} failed: $_"
                    }

                    Start-Sleep -Seconds 1 # Optional: Add delay between requests
                }
            }
            catch {
                Write-Host "Error during login for ${username}: $_"
            }
        }

        # Execute the function with the user's credentials
        RegisterAndAuthenticate -username $using:user.username -password $using:user.password
    }
}

# Wait for all jobs to complete
Get-Job | Wait-Job | Receive-Job
