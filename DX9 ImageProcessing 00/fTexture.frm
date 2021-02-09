VERSION 5.00
Begin VB.Form fTexture 
   Caption         =   "Form1"
   ClientHeight    =   6945
   ClientLeft      =   60
   ClientTop       =   405
   ClientWidth     =   10005
   LinkTopic       =   "Form1"
   ScaleHeight     =   463
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   667
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer Timer2 
      Enabled         =   0   'False
      Interval        =   1000
      Left            =   6240
      Top             =   3960
   End
   Begin VB.Timer Timer1 
      Enabled         =   0   'False
      Interval        =   10
      Left            =   5280
      Top             =   3960
   End
End
Attribute VB_Name = "fTexture"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private SHAD      As cDXShader

Private WW As Single
Private HH As Single



Private Sub Form_Load()

    ScaleMode = vbPixels

' TEXTURE dimensions
'WW = 450
'HH = 300
WW = 784
HH = 520
    
    Me.Height = HH * Screen.TwipsPerPixelY - (ScaleHeight * Screen.TwipsPerPixelY - Height)
    Me.Width = WW * Screen.TwipsPerPixelX



    Set SHAD = New cDXShader

    SHAD.INIT fTexture.hWnd, fTexture.ScaleWidth * 1, fTexture.ScaleHeight, _
              App.Path & "\ShaderVS.txt", _
              App.Path & "\ShaderPS.txt", False

'    SHAD.LoadTextureFromFile App.Path & "\test.jpg"
    SHAD.LoadTextureFromFile App.Path & "\test2.jpg"

End Sub


Private Sub Form_Activate()
    Dim V         As D3DVECTOR
    V.X = WW: V.Y = HH: V.Z = 0
    SHAD.SetVariableFloat3 SHAD.getRegisterNum("texRes"), V


    Timer1.Enabled = True
    Timer2.Enabled = True

End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    SHAD.RENDER
End Sub

Private Sub Timer1_Timer()
    Dim V         As D3DVECTOR

    V.X = Timer ' (Timer) - Int(Timer)
    SHAD.SetVariableFloat3 SHAD.getRegisterNum("iTime"), V
    
    
    SHAD.RENDER
    DoEvents
End Sub

Private Sub Timer2_Timer()
    fTexture.Caption = "FPS: " & SHAD.FPS
    SHAD.FPS = 0
End Sub
