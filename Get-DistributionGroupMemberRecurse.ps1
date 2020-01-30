Add-PSSnapin *exchange*

function Get-DistributionGroupMemberRecurse {
    param( [parameter(Mandatory=$true)] $Group, [string[]] $AlreadySeenGroups )
    if ($AlreadySeenGroups -eq $null) {
        $AlreadySeenGroups += $Group
    }

    $AllMembers = Get-DistributionGroupMember -Identity $Group
    if ($AllMembers) {
        $MbxMembers = $AllMembers | Where-Object { $_.RecipientTypeDetails -like "UserMailbox" } | `
            Select-Object -ExpandProperty SamAccountName
        $UnseenGroupMembers = $AllMembers | `
            Where-Object { $_.RecipientTypeDetails -eq "MailUniversalSecurityGroup" -or $_.RecipientTypeDetails -eq "MailUniversalDistributionGroup" } | `
            Where-Object { $AlreadySeenGroups -notcontains $_.SamAccountName }
        $AlreadySeenGroups += $AllMembers | `
            Where-Object { $_.RecipientTypeDetails -eq "MailUniversalSecurityGroup" -or $_.RecipientTypeDetails -eq "MailUniversalDistributionGroup" } | `
            Select-Object -ExpandProperty SamAccountName
    
        if (@($UnseenGroupMembers).Length -gt 0) {
            ForEach ( $Group in $UnseenGroupMembers ) {
                Write-Verbose $Group.SamAccountName
                $AlreadySeenGroups | Out-String | Write-Verbose
                $MbxMembers += Get-DistributionGroupMemberRecurse -Group $Group.SamAccountName -AlreadySeenGroups $AlreadySeenGroups
            }
        }

        $MbxMembers | Select-Object -Unique
    }
}
