VERSION 5.00
Begin VB.Form fMain 
   Caption         =   "fMain"
   ClientHeight    =   6345
   ClientLeft      =   60
   ClientTop       =   405
   ClientWidth     =   9375
   LinkTopic       =   "Form1"
   ScaleHeight     =   6345
   ScaleWidth      =   9375
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "fMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' - Roberto Mior
' - reexre

Option Explicit

Private Sub Form_Activate()
    MAINLOOP
End Sub

Private Sub Form_Load()
    Me.Height = 480 * Screen.TwipsPerPixelY - Me.ScaleHeight + Me.Height
    Me.Width = Int(16 / 9 * Me.ScaleHeight)
    INITTV3D
End Sub

Private Sub Form_Resize()
    SW = Me.ScaleHeight
    SH = Me.ScaleWidth
    AR = SW / SH
End Sub

Private Sub Form_Unload(Cancel As Integer)
    EXITTV3D
    End
End Sub
