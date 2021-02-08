VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Raymarching using Direct3D9 shaders"
   ClientHeight    =   8085
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   12705
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   539
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   847
   StartUpPosition =   1  'CenterOwner
   Begin VB.Timer tmrFPS 
      Interval        =   1000
      Left            =   4320
      Top             =   3540
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'-------------------- MY TEST
Private ShaderClass As cDXShader
Private bIsActive As Boolean



Private Sub Form_Load()
'-------------------- MY TEST
    Set ShaderClass = New cDXShader




    ShaderClass.INIT Me.hWnd, Me.ScaleWidth, Me.ScaleHeight, _
                     App.Path & "\vs.txt", _
                     App.Path & "\ps.txt"


    Me.Show
    MainLoop

End Sub
Private Sub MainLoop()
    Dim tTime     As D3DVECTOR

    bIsActive = True
    Do While bIsActive

        tTime.X = Timer
       ShaderClass.SetVariableFloat3 ShaderClass.getRegisterNum("MYTIME"), tTime

        ShaderClass.RENDER
        DoEvents
    Loop
End Sub
Private Sub Form_QueryUnload( _
        ByRef Cancel As Integer, _
        ByRef UnloadMode As Integer)
    bIsActive = False
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Set ShaderClass = Nothing
End Sub

Private Sub tmrFPS_Timer()
    Me.Caption = "FPS: " & ShaderClass.FPS
    ShaderClass.FPS = 0
End Sub
