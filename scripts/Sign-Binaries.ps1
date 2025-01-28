$SignTool = "${Env:ProgramFiles(x86)}/Windows Kits/10/bin/10.0.26100.0/x64/signtool.exe"
$SignArgs = @(
    'sign'
    '/v'  # Verbose output
    '/debug'  # Display debugging information
    '/fd', 'SHA256'  # File digest algorithm
    '/tr', 'http://timestamp.acs.microsoft.com'  # Timestamp server
    '/td', 'SHA256'  # Timestamp digest algorithm
    '/dlib', "$Env:USERPROFILE/.nuget/packages/microsoft.trusted.signing.client/1.0.60/bin/x64/Azure.CodeSigning.Dlib.dll"
    '/dmdf', './signing.json'  # Metadata file
)
foreach ($Binary in Get-ChildItem 'bin') {
    & $SignTool @SignArgs $Binary.FullName
}
