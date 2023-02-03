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
            if (!([string]::IsNullOrEmpty($uefiSetting.Name)) -and !([string]::IsNullOrEmpty($uefiSetting.CurrentValue))) {
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
            if (!([string]::IsNullOrEmpty($uefiSettingSplit[0])) -and !([string]::IsNullOrEmpty($uefiSettingSplit[1]))) {
                $resultXML += $(GenerateXML $($uefiSettingSplit[0]) $($uefiSettingSplit[1]))
            }
        }
        write-verbose "[core][lenovo][xml] Done generating"
    }

    # Run WMI query if manufacturer is Dell Inc.
    if ($manufacturer -eq "dell inc.") {
        write-verbose "[core][dell][wmi] Gathering UEFI settings: Part 1"
        $uefiSettings = $(Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName EnumerationAttribute)
        write-verbose "[core][dell][wmi] Done gathering UEFI settings: Part 1"
        write-verbose "[core][dell][wmi] Gathering UEFI settings: Part 2"
        $uefiSettings += $(Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName IntegerAttribute)
        write-verbose "[core][dell][wmi] Done gathering UEFI settings: Part 2"
        write-verbose "[core][dell][wmi] Gathering UEFI settings: Part 3"
        $uefiSettings += $(Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName StringAttribute)
        write-verbose "[core][dell][wmi] Done gathering UEFI settings: Part 3"
        write-verbose "[core][dell][wmi] Gathering UEFI settings: Boot Order"
        $uefiSettingsBootOrders = $(Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName BootOrder)
        write-verbose "[core][dell][wmi] Done gathering UEFI settings: Boot Order"
        write-verbose "[core][dell][wmi] Done gathering all UEFI settings, found $($($uefiSettings.count) + $($uefiSettingsBootOrders.count)) settings"
        write-verbose "[core][dell][xml] Generating..."
        foreach ($uefiSetting in $uefiSettings) {
            if (!([string]::IsNullOrEmpty($uefiSetting.AttributeName)) -and !([string]::IsNullOrEmpty($uefiSetting.CurrentValue))) {
                $resultXML += $(GenerateXML $($uefiSetting.AttributeName) $($uefiSetting.CurrentValue))
            }
        } 
        foreach ($uefiSettingsBootOrder in $uefiSettingsBootOrders) {
            if (!([string]::IsNullOrEmpty($uefiSettingsBootOrder.BootListType)) -and !([string]::IsNullOrEmpty($uefiSettingsBootOrder.BootOrder))) {
                $resultXML += $(GenerateXML $("Bootorder:",$($uefiSettingsBootOrder.BootListType) -join " ") $($(if ($($uefiSettingsBootOrder.IsActive) -eq "1"){"Active"}else{"Inactive"}),$($uefiSettingsBootOrder.BootOrder) -join ": "))
            }
        }        
        write-verbose "[core][dell][xml] Done generating"
    }
}
Catch {
    write-verbose $Error[0]
}

write-verbose "[core][xml] Sending report..."
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::WriteLine($resultXML)
write-verbose "[core][xml] Done sending report"
write-verbose "[core] Exiting"