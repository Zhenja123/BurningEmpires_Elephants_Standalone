# Burning Empires Elephants Standalone

Standalone Bannerlord module installer and runtime source for public inspection.

## Contents

- `source/` — C# source, project file, and PowerShell build helper for the standalone runtime.
- `installer/` — the v5 BAT/PowerShell installer package, including the known-good tested runtime DLL and Aserai market XML patch.

## Current tested release

The DLL included in `installer/bin/Win64_Shipping_Client/BE_Elephants_Standalone_Runtime.dll` is the binary supplied after a successful in-game test and packaged in installer v5.

- DLL size: 13,312 bytes
- SHA-256: `9c6696d8104424708a9bf95333e3ada75e8e2a43aa034c4b161fdc744e93e50e`

The source is included so users and reviewers can inspect how the runtime works. **The included source build has not been independently verified as byte-for-byte/build-equivalent to the tested DLL**, so rebuilding from source should be treated as a separate build and retested in-game before replacing the tested binary.

## Install

1. Install the original **Burning Empires Elephants** module first.
2. Extract the `installer/` folder to a normal folder outside the game's `Modules` directory.
3. Run `installer/Install-ElephantsStandalone.bat`.
4. Follow the prompts to locate the Bannerlord game folder if needed.
5. Enable **Burning Empires - Elephants Standalone** in the launcher and test it before removing the original module.

The installer creates a separate standalone module and leaves the original `BurningEmpires_Elephants` module unchanged. It copies the source module's assets/XML into the standalone folder and applies the market patch to that standalone copy.

## Build source

Requirements: Windows, .NET SDK capable of targeting .NET Framework 4.7.2, and a Bannerlord installation with the required game assemblies.

1. Open `source/build.ps1` and adjust `$GameBin` if Bannerlord is installed elsewhere.
2. Open PowerShell in the `source/` directory.
3. Run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build.ps1"
   ```

4. Review the build output. Test any rebuilt DLL in-game before distributing it.

## Notes for reviewers

- The standalone installer requires the original Burning Empires Elephants module to supply its assets and XML source files.
- The market XML patch is applied only to the standalone copy.
- This repository packages a tested runtime binary, but the source-to-binary correspondence has not yet been independently verified.
- No license is declared here. Add a license only after confirming you have the rights to license the source and included materials.
