Function Parse-DiskpartList {
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