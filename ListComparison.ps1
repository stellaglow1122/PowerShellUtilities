[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$Form = New-Object System.Windows.Forms.Form
$Form.Size = New-Object System.Drawing.Size(1920,1080)
$Form.Text = "List Comparison"

$TextBoxName1 = New-Object System.Windows.Forms.Textbox
$TextBoxName1.Location = New-Object System.Drawing.Point(100,150)
$TextBoxName1.Size = New-Object System.Drawing.Size(800,100)
$TextBoxName1.Text = "List1"
$Form.Controls.Add($TextBoxName1)

$TextBox1 = New-Object System.Windows.Forms.Textbox
$TextBox1.Location = New-Object System.Drawing.Point(100,200)
$TextBox1.Size = New-Object System.Drawing.Size(800,400)
$TextBox1.Multiline = $true
$TextBox1.ScrollBars = "Vertical"
$Form.Controls.Add($TextBox1)

$TextBoxName2 = New-Object System.Windows.Forms.Textbox
$TextBoxName2.Location = New-Object System.Drawing.Point(1000,150)
$TextBoxName2.Size = New-Object System.Drawing.Size(800,100)
$TextBoxName2.Text = "List2"
$Form.Controls.Add($TextBoxName2)

$TextBox2 = New-Object System.Windows.Forms.Textbox
$TextBox2.Location = New-Object System.Drawing.Point(1000,200)
$TextBox2.Size = New-Object System.Drawing.Size(800,400)
$TextBox2.Multiline = $true
$TextBox2.ScrollBars = "Vertical"
$Form.Controls.Add($TextBox2)

$objLabel1 = New-Object System.Windows.Forms.label
$objLabel1.Location = New-Object System.Drawing.Size(100,650)
$objLabel1.Size = New-Object System.Drawing.Size(400,30)
$objLabel1.BackColor = "Transparent"
$objLabel1.ForeColor = "black"
$objLabel1.Text = "Values that can be found in list1 but not in list2"
$Form.Controls.Add($objLabel1)

$objLabel2 = New-Object System.Windows.Forms.label
$objLabel2.Location = New-Object System.Drawing.Size(1000,650)
$objLabel2.Size = New-Object System.Drawing.Size(400,30)
$objLabel2.BackColor = "Transparent"
$objLabel2.ForeColor = "black"
$objLabel2.Text = "Values that can be found in list2 but not in list1"
$Form.Controls.Add($objLabel2)

$TextBox3 = New-Object System.Windows.Forms.Textbox
$TextBox3.Location = New-Object System.Drawing.Point(100,680)
$TextBox3.Size = New-Object System.Drawing.Size(800,300)
$TextBox3.Multiline = $true
$TextBox3.ScrollBars = "Vertical"
$Form.Controls.Add($TextBox3)

$TextBox4 = New-Object System.Windows.Forms.Textbox
$TextBox4.Location = New-Object System.Drawing.Point(1000,680)
$TextBox4.Size = New-Object System.Drawing.Size(800,300)
$TextBox4.Multiline = $true
$TextBox4.ScrollBars = "Vertical"
$Form.Controls.Add($TextBox4)

function Btn_Click(){
    $TextBox3.Text = ""
    $TextBox4.Text = ""
    $list1Name = $TextBoxName1.Text
    $list2Name = $TextBoxName2.Text
    $objLabel1.Text = "Values that can be found in $list1Name but not in $list2Name"
    $objLabel2.Text = "Values that can be found in $list2Name but not in $list1Name"
    $list1 = $TextBox1.Text.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)
    $list2 = $TextBox2.Text.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)
    $list1 | ForEach-Object {
        if (!($list2 -contains $_))
        {
            $TextBox3.Text += $_ + [System.Environment]::NewLine
        }
    }
    $list2 | ForEach-Object {
        if (!($list1 -contains $_))
        {
            $TextBox4.Text += $_ + [System.Environment]::NewLine
        }
    }
}

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(850,600)
$Button.Size = New-Object System.Drawing.Size(200,50)
$Button.Text = "Compare"
$Button.Add_Click($function:Btn_Click)

$Form.Controls.Add($Button)

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()
