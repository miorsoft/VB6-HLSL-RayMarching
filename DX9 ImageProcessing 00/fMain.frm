VERSION 5.00
Begin VB.Form fMain 
   Caption         =   "form"
   ClientHeight    =   9465
   ClientLeft      =   120
   ClientTop       =   420
   ClientWidth     =   12675
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   9.75
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   ScaleHeight     =   631
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   845
   StartUpPosition =   3  'Windows Default
   Begin VB.PictureBox PIC 
      Appearance      =   0  'Flat
      BackColor       =   &H80000005&
      ForeColor       =   &H80000008&
      Height          =   7335
      Left            =   240
      ScaleHeight     =   487
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   455
      TabIndex        =   0
      Top             =   240
      Width           =   6855
   End
End
Attribute VB_Name = "fMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Form_Activate()
    MAINLOOP

End Sub

Private Sub Form_Load()

PIC.Width = 512
PIC.Height = 512

    INITTV3D

End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
    do_loop = False

End Sub

Private Sub Form_Unload(Cancel As Integer)
    EXITTV3D

End Sub


Public Sub MAINLOOP()

    do_loop = True

    Do

        RENDERtv3D
        DoEvents

    Loop While do_loop

End Sub
