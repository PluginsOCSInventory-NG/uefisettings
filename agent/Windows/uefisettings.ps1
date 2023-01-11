<#
.Synopsis
This script gathers uefi settings and there values from Windows Management Instrumentation (WMI).

.Description
This script gathers uefi settings and there values from Windows Management Instrumentation (WMI).
Based on manufacturer the correct query will be run. Output of the query wil be formatted to an xml output.

#>

[CmdletBinding()]
Param (
)

# Set default ErrorAction to catch Get-CimInstance errors
$ErrorActionPreference = 'Stop'

###
# Functions
###
function GenerateXML {
    param (
        [Parameter(Mandatory=$True)][string]$uefiSetting,
        [Parameter(Mandatory=$True)][string]$uefiValue
    )
        # Truncate string if greater then 255 chars
        $uefiSetting = $($($uefiSetting.subString(0, [System.Math]::Min(255, $uefiSetting.Length))))
        $uefiValue = $($($uefiValue.subString(0, [System.Math]::Min(255, $uefiValue.Length))))

        $generateXML += "<UEFISETTINGS>`n"
        $generateXML += "<UEFISETTING>"+ $($uefiSetting) +"</UEFISETTING>`n"
        $generateXML += "<UEFIVALUE>"+ $($uefiValue) +"</UEFIVALUE>`n"
        $generateXML += "</UEFISETTINGS>`n"
        return $generateXML
}

###
# Core
###
Try {
    # Determine the manufacturer
    $manufacturer = $((Get-CimInstance -Namespace root\CIMv2 -Class Win32_ComputerSystem).Manufacturer)
    write-verbose "[core] HManufacturer hardware is $($manufacturer)"

    # Run WMI query if manufacturer is HP
    if ($manufacturer -eq "hp") {
        write-verbose "[core][hp][wmi] Gathering UEFI settings"
        $uefiSettings = $(Get-CimInstance -Namespace root\hp\InstrumentedBIOS -ClassName HP_BIOSEnumeration)
        write-verbose "[core][hp][wmi] Done gathering UEFI settings, found $($uefiSettings.count) settings"
        write-verbose "[core][hp][xml] Generating..."
        foreach ($uefiSetting in $uefiSettings) {
            if ($uefiSetting.Name -and $uefiSetting.CurrentValue) {
                $resultXML += $(GenerateXML $($uefiSetting.Name) $($uefiSetting.CurrentValue))
            }
        } 
    }

    # Run WMI query if manufacturer is Lenovo
    if ($manufacturer -eq "lenovo") {
        write-verbose "[core][lenovo][wmi] Gathering UEFI settings"
        $uefiSettings = $(Get-CimInstance -Namespace root\wmi -ClassName Lenovo_BiosSetting)
        write-verbose "[core][lenovo][wmi] Done gathering UEFI settings, found $($uefiSettings.count) settings"
        write-verbose "[core][lenovo][xml] Generating..."
        foreach ($uefiSetting in $uefiSettings) {
            $uefiSettingSplit = $(($uefiSetting.CurrentSetting).Split(','))
            if ($uefiSettingSplit[0] -and $uefiSettingSplit[1]) {
                $resultXML += $(GenerateXML $($uefiSettingSplit[0]) $($uefiSettingSplit[1]))
            }
        }
        write-verbose "[core][lenovo][xml] Done generating"
    }
}
Catch {
    write-verbose $Error[0]
}

write-verbose "[core][xml] Sending report..."
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[Console]::WriteLine($resultXML)
write-verbose "[core][xml] Done sending report"
write-verbose "[core] Exiting"