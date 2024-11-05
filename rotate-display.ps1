<#
.SYNOPSIS
    Script to toggle screen orientation between landscape and portrait modes.

.DESCRIPTION
    This script checks the current screen orientation and toggles it between landscape (0 degrees) and portrait (90 degrees) modes.
    The core functionality is encapsulated in the `Set-ScreenOrientation` function, which accepts the desired orientation as a parameter.
    If the current orientation is 0 (landscape), it switches to 90 (portrait). If the current orientation is 90 (portrait), it switches to 0 (landscape).

.PARAMETER Orientation
    Numeric value representing the screen orientation.
    Possible values:
    0   - Landscape (DMDO_DEFAULT)
    90  - Portrait (DMDO_90)
    180 - Reverse landscape (DMDO_180)
    270 - Reverse portrait (DMDO_270)

.EXAMPLE
    .\ToggleScreenOrientation.ps1
    Toggles the screen orientation between landscape and portrait modes.

.NOTES
    Requires Windows PowerShell with Add-Type and .NET support.
#>

Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class ScreenOrientation
    {
        // Constants for display settings
        // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsa
        private const int ENUM_CURRENT_SETTINGS = -1;
        private const int CDS_UPDATEREGISTRY = 0x01;
        private const int CDS_TEST = 0x02;
        private const int DISP_CHANGE_SUCCESSFUL = 0;

        // Constants for screen orientation
        // https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-devmodea
        private const int DMDO_DEFAULT = 0;
        private const int DMDO_90 = 1;
        private const int DMDO_180 = 2;
        private const int DMDO_270 = 3;

        [StructLayout(LayoutKind.Sequential)]
        public struct DEVMODE
        {
            private const int CCHDEVICENAME = 0x20;
            private const int CCHFORMNAME = 0x20;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHDEVICENAME)]
            public string dmDeviceName;

            public short dmSpecVersion;
            public short dmDriverVersion;
            public short dmSize;
            public short dmDriverExtra;
            public int dmFields;

            public int dmPositionX;
            public int dmPositionY;
            public ScreenOrientation.DM dmDisplayOrientation;
            public int dmDisplayFixedOutput;

            public short dmColor;
            public short dmDuplex;
            public short dmYResolution;
            public short dmTTOption;
            public short dmCollate;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHFORMNAME)]
            public string dmFormName;

            public short dmLogPixels;
            public int dmBitsPerPel;
            public int dmPelsWidth;
            public int dmPelsHeight;

            public int dmDisplayFlags;
            public int dmNup;
            public int dmDisplayFrequency;
        }

        // Enum for screen orientation
        // https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-devmodea
        public enum DM : int
        {
            DMDO_DEFAULT = 0,
            DMDO_90 = 1,
            DMDO_180 = 2,
            DMDO_270 = 3
        }

        // P/Invoke to retrieve current display settings
        // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsa
        [DllImport("user32.dll", CharSet = CharSet.Ansi)]
        public static extern int EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);

        // P/Invoke to change display settings
        // https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changedisplaysettingsa
        [DllImport("user32.dll", CharSet = CharSet.Ansi)]
        public static extern int ChangeDisplaySettings(ref DEVMODE lpDevMode, int dwFlags);

        /// <summary>
        /// Retrieves the current screen orientation.
        /// </summary>
        /// <returns>Returns the current screen orientation as a DM enum value.</returns>
        public static DM GetScreenOrientation()
        {
            DEVMODE dm = new DEVMODE();
            dm.dmDeviceName = new string(new char[32]);
            dm.dmFormName = new string(new char[32]);
            dm.dmSize = (short)Marshal.SizeOf(dm);

            if (0 != EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref dm))
            {
                return dm.dmDisplayOrientation;
            }
            return DM.DMDO_DEFAULT;
        }

        /// <summary>
        /// Sets the screen orientation based on the specified DM enum value.
        /// </summary>
        /// <param name="orientation">The desired screen orientation as a DM enum value.</param>
        public static void SetScreenOrientation(DM orientation)
        {
            DEVMODE dm = new DEVMODE();
            dm.dmDeviceName = new string(new char[32]);
            dm.dmFormName = new string(new char[32]);
            dm.dmSize = (short)Marshal.SizeOf(dm);

            if (0 != EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref dm))
            {
                dm.dmDisplayOrientation = orientation;

                // Swap width and height if necessary
                if ((orientation == DM.DMDO_90) || (orientation == DM.DMDO_270) || (orientation == DM.DMDO_DEFAULT))
                {
                    int temp = dm.dmPelsHeight;
                    dm.dmPelsHeight = dm.dmPelsWidth;
                    dm.dmPelsWidth = temp;
                }

                int iRet = ChangeDisplaySettings(ref dm, CDS_TEST);

                if (iRet == DISP_CHANGE_SUCCESSFUL)
                {
                    ChangeDisplaySettings(ref dm, CDS_UPDATEREGISTRY);
                }
            }
        }
    }
"@

# Function to set the screen orientation
function Set-ScreenOrientation {
    param (
        [ValidateSet("0", "90", "180", "270")]
        [string]$Orientation
    )

    # Toggle screen orientation based on the input parameter
    switch ($Orientation) {
        "0" { [ScreenOrientation]::SetScreenOrientation([ScreenOrientation+DM]::DMDO_DEFAULT) }
        "90" { [ScreenOrientation]::SetScreenOrientation([ScreenOrientation+DM]::DMDO_90) }
        "180" { [ScreenOrientation]::SetScreenOrientation([ScreenOrientation+DM]::DMDO_180) }
        "270" { [ScreenOrientation]::SetScreenOrientation([ScreenOrientation+DM]::DMDO_270) }
    }
}

# Main script to toggle screen orientation between 0 and 90
$currentOrientation = [ScreenOrientation]::GetScreenOrientation().ToString()

Write-Output "Current screen orientation: $currentOrientation"

switch ($currentOrientation) {
    "DMDO_DEFAULT" {
        [ScreenOrientation]::SetScreenOrientation([ScreenOrientation+DM]::DMDO_90)
    }
    "DMDO_90" {
        [ScreenOrientation]::SetScreenOrientation([ScreenOrientation+DM]::DMDO_DEFAULT)
    }
    default {
        Write-Output "Current screen orientation is neither 0 nor 90. No changes made."
    }
}
