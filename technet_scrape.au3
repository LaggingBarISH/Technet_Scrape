;   Author:     /u/Just-A-City-Boy
;   Date:       03/16/2020
;   Version:    1.1
;   Notes:      Ugly? Yes. Efficient? Ehhhhhh.
;
;
;-----------------------------------------------------------
;	Modifications:
;	By:	/u/Lagging_BaSE
;	Date: 05.04.2020 / DD.MM.YYYY > Well it's obvious as we are not in May yet, but you never know.
;	Version: 1.1 Modified
;	Mods:
;		- Now supports pages with no attachments.
;		- Improved locations (don't know if i should call this indexing).
;			- Html files now gets their original names.
;			- Pages with attachments now get their own folder for users sake.
;			- Pages without attachments are in their own Tag or Untagged folders.
;		- Sorted link to Date, i was missing some pages by popular.
;	Personal Usage: technet_scrape.exe>technet_scrape_log.txt
;	Notes: This is my first time ever using Auto It so be easy on me if i made something dumb.
;	Note 2: While this script downloads all links from Technet it can't download files attached as text. Ex: ...... Download New Version From: www.example.com
;	Somebody can probably write this in AutoIt or their favorite programming language and filter for http & https links in the html page and also download those as attachments.
;	I am too lazy to do that and also don't know and web oriented programming like downloading and parsing files from web.
;-----------------------------------------------------------
;
;

#include <String.au3>
#include <File.au3>
#include <Array.au3>
#include <Inet.au3>

Dim $freeSpace, $sDrive, $sDir, $sFName, $sFExt
Dim $baseURL, $source, $sData, $sURL, $fileSource, $downloadURL, $fileName
$baseURL = "https://gallery.technet.microsoft.com"
Dim $dwnl, $untag, $space, $writeConsole
$dwnl = "\WebSite-Downloads\"
$untag = "Untagged\"
$space = "                                                                                                                                                                                                                                                               " ; Used to fancy the output. Why so long: One line in the output (I don't remember), lenght is 246 chars so i gave it ~30 chars for whatever the case may be totalling to 300 chars/line. Note: Longest in first 20 search pages, i don't have a full list yet.
DirCreate(@ScriptDir & $dwnl)
DirCreate(@ScriptDir & $dwnl & $untag)

for $i = 124 to 124
	$freeSpace = DriveSpaceFree("C:\")
	if $freeSpace < 1000 then Exit ; 10000MB = 10GB

	ConsoleWrite("------------------------------------------------------------------------------------------------------------------------" & @CRLF & "Grabbing Source for Page " & $i & " ... " & @CRLF & @CRLF)
	$source = _INetGetSource($baseURL & "/site/search?sortBy=Date&pageIndex=" & $i)
	while StringInStr($source, '<tr class="itemRow">') ; While there's still projects on the page
		;ConsoleWrite("-" & $sURL & @CRLF)
		$sData = _StringBetween($source, '<tr class="itemRow">', '</div>') ; Get the project body text
		if not IsArray($sData) then ; The page doesn't have script rows
			ContinueLoop
		EndIf

		$sURL = _StringBetween($sData[0], '<a href="', '">') ; Get the project URL
		$desc = _INetGetSource($baseURL & $sURL[0] & "/description") ; Grab the seperate description page
		$remove = _StringBetween($desc, "<head>", "</head>")
		if IsArray($remove) Then ; Strip out the technet scripts or else get redirected on load
			$desc = StringReplace($desc, "<head>" & $remove[0] & "</head>", '')
		EndIf

		$fileSource = _INetGetSource($baseURL & $sURL[0]) ; Get the project page source
		$downloadURL = _StringBetween($fileSource, '" data-url="', '" class')

		$tagSource = _StringBetween($fileSource, '<div id="Tags">', '</div>')
		if IsArray($tagSource) Then
			$tag = _StringBetween($tagSource[0], '>', '</a>')
			if IsArray($tag) Then
				DirCreate(@ScriptDir & $dwnl & $tag[0])
				$saveFolder = @ScriptDir & $dwnl & $tag[0] & "\"
			Else
				$saveFolder = @ScriptDir & $dwnl & $untag
			EndIf
		Else
			$saveFolder = @ScriptDir & $dwnl & $untag
		EndIf

		if not IsArray($downloadURL) then ; The script does not have a download
			ConsoleWrite("   !!!HTML ONLY!!!   ") ; Downloads html only files.
		Else
			$fileName = _PathSplit($baseURL & $downloadURL[0], $sDrive, $sDir, $sFName, $sFExt)
			$sFName = StringReplace($sFName, "%20", " ")
			$saveFolder = StringTrimRight($saveFolder, 1) & "\" & StringTrimLeft($sURL[0], 1) & "\" ; TrimLeft is really unnecessary, but it will make the console output look much nicer by making all dividers backslashes.
			DirCreate($saveFolder)
			InetGet($baseURL & $downloadURL[0], $saveFolder & $sFName & $sFExt) ; Download the attachment
			ConsoleWrite("                     ") ; Alignment for html only text.
		EndIf

		$writeConsole = "Saving: " & $sURL[0] & " as: " & StringTrimLeft($sURL[0], 1) & ".html to: " & $saveFolder & " ... "
		ConsoleWrite($writeConsole)
		FileWrite(StringTrimRight($saveFolder, 1) & "\" & StringTrimLeft($sURL[0], 1) & ".html", $desc) ; Save the description
		ConsoleWrite(StringTrimLeft($space, StringLen($writeConsole)) & "     ") ; Min 5 spaces.
		ConsoleWrite("Successfully Saved." & @CRLF)
		$source = StringReplace($source, '<tr class="itemRow">' & $sData[0] & '</div>', '') ; Removed the processed line or forever be stuck in a loop
	WEnd
Next

Exit