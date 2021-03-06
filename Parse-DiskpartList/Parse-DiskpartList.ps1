Function Parse-DiskpartList {
<#
	.SYNOPSIS
		The function converts "raw" "diskpart list" output into an object
	.DESCRIPTION
		The function has been created to convert output of "diskpart list" command
		into an object. 
		It can parse output of the following "List" commands:
			DISK        - Display a list of disks. For example, LIST DISK.
			PARTITION   - Display a list of partitions on the selected disk.
			VOLUME      - Display a list of volumes. For example, LIST VOLUME.
			VDISK       - Displays a list of virtual disks.
		The standard output is a table which consist of a title row and several data row. Example:
			DISKPART> list volume

			Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
			----------  ---  -----------  -----  ----------  -------  ---------  --------
			Volume 0     D   Data         NTFS   Mirror      1863 GB  Healthy
			Volume 1     E   de-DE_L2     CDFS   DVD-ROM      382 MB  Healthy
			Volume 2         System Rese  NTFS   Partition    100 MB  Healthy    System
			Volume 3     C                NTFS   Partition     55 GB  Healthy    Boot 
		The script will create an array of objects which consist of properties named after columns
		(i.e. "Volume ###", "Label" etc)
		Example: 
			Volume ### : Volume 0
			Ltr        : D
			Label      : Data
			Fs         : NTFS
			Type       : Mirror
			Size       : 1863 GB
			Status     : Healthy
			Info       : 

			Volume ### : Volume 1
			Ltr        : E
			Label      : de-DE_L2
			Fs         : CDFS
			Type       : DVD-ROM
			Size       : 382 MB
			Status     : Healthy
			Info       : 

			Volume ### : Volume 2
			Ltr        : 
			Label      : System Rese
			Fs         : NTFS
			Type       : Partition
			Size       : 100 MB
			Status     : Healthy
			Info       : System

			Volume ### : Volume 3
			Ltr        : C
			Label      : 
			Fs         : NTFS
			Type       : Partition
			Size       : 55 GB
			Status     : Healthy
			Info       : Boot
	.PARAMETER  ParameterA
		The description of the ParameterA parameter.

	.PARAMETER  DiskpartOutput
		An array which contains the output of "diskpart list" command 
		(i.e. $DiskpartOutput = ("list volume" | diskpart) 
	.EXAMPLE
		$objDiskpartList = Parse-DiskpartList -DiskpartOutput $DiskpartOutput
		System.String,System.Int32
	.OUTPUTS
		System.Array
	.NOTES
		The function is free to use\copy or modify. In case of any issues or requests, feel free to ask me via GitHub
	.LINK
		https://github.com/FutureIsHere
	.LINK
		https://github.com/FutureIsHere/PowerShell-Functions/tree/master/Parse-DiskpartList
#>

	param (
		[parameter(Position=0,Mandatory=$true)]
		[array]$DiskpartOutput
	)
	#remove empty lines
	$tmpArray = @()
	foreach ($line in $DiskpartOutput) {
		$line = $line.TrimStart()
		if ($line.length -ne 0) {
			$tmpArray+=$line
		}
	}
	$DiskpartOutput = $tmpArray

	#find the line with dashes (i.e. "----- ---- --- "
	$indexTitleSeparatorLine = $null
	$indexCurrentLine = 0
	foreach ($line in $DiskpartOutput) {
		if ($line -match "---") {
			$indexTitleSeparatorLine = $indexCurrentLine
			break
		}
		$indexCurrentLine++ 
	}
	if ($indexTitleSeparatorLine -eq $null) {
		throw ("ERROR!!! Incorect format of diskpart output (no separation line (----))")
	}
	
	#get the last data line index (the line before "DISKPART>" line)
	$indexLastDataLine = $null
	for ($i = $indexTitleSeparatorLine; $i -lt $DiskpartOutput.Length; $i++) {
		if ($DiskpartOutput[$i] -match "DISKPART>") {
			$indexLastDataLine = $i - 1 	#the line above
			break
		}
	}
	if ($indexLastDataLine -eq $null) {
		throw ("ERROR!!! Incorect format of diskpart output (no ending line)")
	}

	#calculate columns's width (i.e. "-----" - 5)
	$arrColumnWidth = @()
	$arrColumns = $DiskpartOutput[$indexTitleSeparatorLine].Split()
	foreach($Column in $arrColumns) {
		if ($Column.Length -ne 0) {
			#include only not empty column titles
			$arrColumnWidth+=$Column.Length
		}
	}
	
	#get columns's title
	$ColumnTitleLine = $DiskpartOutput[$indexTitleSeparatorLine-1]	#we assume, that the title line is above the separation line
	$arrColumnTitle = @()
	$indexCurrentColumnTitle = 0		#position of the first character of column's title in the title line
	for ($i = 0; $i -lt $arrColumnWidth.Length; $i++) {
		if ($i -ne ($arrColumnWidth.Length -1)) {
			$ColumnTitle = $ColumnTitleLine.Substring($indexCurrentColumnTitle,$arrColumnWidth[$i])
			$indexCurrentColumnTitle = $indexCurrentColumnTitle + 2 		#at least 2 whitespaces separates columns
			$indexCurrentColumnTitle = $indexCurrentColumnTitle + $arrColumnWidth[$i]		#move the position index to the next column
		} else {
			#get the last element
			$ColumnTitle = $ColumnTitleLine.Substring($indexCurrentColumnTitle)
		}
		$ColumnTitle = $ColumnTitle.Trim()
		$arrColumnTitle += $ColumnTitle
	}
	
	#parse the data
	#the data will be stored in an array of objects
	$arrDiskpartListData = @()
	for ($i = $indexTitleSeparatorLine + 1; $i -le $indexLastDataLine; $i++) {
		#create an object which contains the data
		$objData = New-Object psobject
		foreach ($Column in $arrColumnTitle) {
			$objData | Add-Member -Name "$Column" -MemberType NoteProperty -Value $null
		}
		$indexCurrentColumn = 0
		$indexCurrentColumnData = 0		#position of the first character of data column
		$DataLine = $DiskpartOutput[$i]
		foreach ($Column in $arrColumnTitle) {
			if ($indexCurrentColumn -lt ($arrColumnTitle.Length - 1)) {
				$Data = $DataLine.Substring($indexCurrentColumnData,$arrColumnWidth[$indexCurrentColumn])
				$indexCurrentColumnData=$indexCurrentColumnData + 2 	#at least 2 whitespaces separates columns
				$indexCurrentColumnData=$indexCurrentColumnData + $arrColumnWidth[$indexCurrentColumn]
				$indexCurrentColumn++			
			} else {
				$Data = $DataLine.Substring($indexCurrentColumnData)
			}
			$Data = $Data.Trim()
			$objData.$Column = $Data
		}
		$arrDiskpartListData+= $objData
	}
	return $arrDiskpartListData
}