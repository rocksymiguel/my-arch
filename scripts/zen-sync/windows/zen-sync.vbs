' Lanza zen-sync.ps1 sin ventana de consola. Se usa desde los accesos directos de Windows.
Set fso = CreateObject("Scripting.FileSystemObject")
args = ""
For Each a In WScript.Arguments
  args = args & " """ & a & """"
Next
ps1 = fso.GetParentFolderName(WScript.ScriptFullName) & "\zen-sync.ps1"
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """" & args, 0, False
