Burning Empires Elephants - Standalone Runtime Source Fix (v12)

IMPORTANT: This archive contains source code, not a ready-to-install compiled DLL.
The older DLL from previous archives was not rebuilt after the source correction.

Correction included:
- StandaloneElephantAssets.IsElephant(Agent) checks agent.Monster directly.
  The previous implementation checked agent.MountAgent.Monster, which can fail
  when the method is passed the elephant agent itself and can block attack logic.
- Other runtime behavior is intentionally unchanged.

Build on the Windows PC that has Bannerlord installed:
1. Extract this ZIP outside the game's Modules folder.
2. If necessary, edit build.ps1 so $GameBin points to your Bannerlord
   bin\Win64_Shipping_Client directory.
3. Run PowerShell in the extracted project folder:
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build.ps1"
4. On success, the new DLL is created at:
   bin\Debug
et472\BE_Elephants_Standalone_Runtime.dll

Do not install this source ZIP directly. The new DLL must replace the old DLL
inside the standalone installer package before running the installer.

The action_types/action_sets manifest registration is a separate data-side
change and should be retained in the standalone SubModule.xml. Your previous
manifest test used the old DLL, so it did not test this source correction.

Scope: only elephant recognition in the runtime was corrected. No installer,
model, saddle, or unrelated gameplay changes are included here.
