<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	02/10/2018 10:26
	 Created by:   	danie
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
function Global:datetimepicker{
Add-Type -AssemblyName System.Windows.Forms

# Main Form
$mainForm = New-Object System.Windows.Forms.Form
$font = New-Object System.Drawing.Font("Consolas", 13)
$mainForm.Text = " Pick Time Frame"
$mainForm.Font = $font
$mainForm.ForeColor = "Black"
$mainForm.BackColor = "GradientActiveCaption"
$mainForm.Width = 300
$mainForm.Height = 200

# DatePicker Label
$datePickerLabel = New-Object System.Windows.Forms.Label
$datePickerLabel.Text = "date"
$datePickerLabel.Location = "15, 10"
$datePickerLabel.Height = 22
$datePickerLabel.Width = 90
$mainForm.Controls.Add($datePickerLabel)

# MinTimePicker Label
$minTimePickerLabel = New-Object System.Windows.Forms.Label
$minTimePickerLabel.Text = "min-time"
$minTimePickerLabel.Location = "15, 45"
$minTimePickerLabel.Height = 22
$minTimePickerLabel.Width = 90
$mainForm.Controls.Add($minTimePickerLabel)

# MaxTimePicker Label
$maxTimePickerLabel = New-Object System.Windows.Forms.Label
$maxTimePickerLabel.Text = "max-time"
$maxTimePickerLabel.Location = "15, 80"
$maxTimePickerLabel.Height = 22
$maxTimePickerLabel.Width = 90
$mainForm.Controls.Add($maxTimePickerLabel)

# DatePicker
$datePicker = New-Object System.Windows.Forms.DateTimePicker
$datePicker.Location = "110, 7"
$datePicker.Width = "150"
$datePicker.Format = [windows.forms.datetimepickerFormat]::custom
$datePicker.CustomFormat = "dd/MM/yyyy"
$mainForm.Controls.Add($datePicker)

# MinTimePicker
$minTimePicker = New-Object System.Windows.Forms.DateTimePicker
$minTimePicker.Location = "110, 42"
$minTimePicker.Width = "150"
$minTimePicker.Format = [windows.forms.datetimepickerFormat]::custom
$minTimePicker.CustomFormat = "HH:mm:ss"
$minTimePicker.ShowUpDown = $TRUE
$mainForm.Controls.Add($minTimePicker)

# MaxTimePicker
$maxTimePicker = New-Object System.Windows.Forms.DateTimePicker
$maxTimePicker.Location = "110, 77"
$maxTimePicker.Width = "150"
$maxTimePicker.Format = [windows.forms.datetimepickerFormat]::custom
$maxTimePicker.CustomFormat = "HH:mm:ss"
$maxTimePicker.ShowUpDown = $TRUE
$mainForm.Controls.Add($maxTimePicker)

# OK Button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = "15, 130"
$okButton.ForeColor = "Black"
$okButton.BackColor = "White"
$okButton.Text = "OK"
$okButton.add_Click({ $mainForm.close() })
$mainForm.Controls.Add($okButton)

[void]$mainForm.ShowDialog()

$Global:DateSelect=$datePicker.text
$Global:Mintime=$minTimePicker.text
$Global:Maxtime=$maxTimePicker.text
	
}
Global:datetimepicker
