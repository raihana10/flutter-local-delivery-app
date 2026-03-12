$adminId = 1
$headers = @{}
$headers.Add("x-admin-id", $adminId.ToString())

function Test-Endpoint {
    param([string]$Url)
    Write-Host "--- Test $Url ---"
    try {
        $result = Invoke-RestMethod -Uri $Url -Method Get -Headers $headers -SkipHttpErrorCheck
        $result | ConvertTo-Json -Depth 5
    } catch {
        $_.ErrorDetails.Message
    }
}

Test-Endpoint "http://localhost:8084/admin/dashboard/kpis"
Test-Endpoint "http://localhost:8084/admin/dashboard/alerts"
Test-Endpoint "http://localhost:8084/admin/users/livreurs"
