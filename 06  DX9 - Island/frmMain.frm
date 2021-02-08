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

Private bIsActive As Boolean



Private Sub Form_Click()


CamMode = (CamMode + 1) Mod 2

End Sub

Private Sub Form_Load()
'-------------------- MY TEST
    Set dxSHADER = New cDXShader

    dxSHADER.INIT Me.hWnd, Me.ScaleWidth, Me.ScaleHeight, _
                     App.Path & "\vs.txt", _
                     App.Path & "\ps.txt", True



    Me.Show
    MainLoop

End Sub
Private Sub MainLoop()


    bIsActive = True
    Do While bIsActive


           DoCamera
        
SetShaderVariables

        dxSHADER.RENDER
        DoEvents
    Loop
End Sub
Private Sub Form_QueryUnload( _
        ByRef Cancel As Integer, _
        ByRef UnloadMode As Integer)
    bIsActive = False
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Set dxSHADER = Nothing
End Sub

Private Sub tmrFPS_Timer()
    Me.Caption = "FPS: " & dxSHADER.FPS & "  Click to change camera mode"
    dxSHADER.FPS = 0
    
    deltaT = Timer - oTimer: If deltaT > 1 Then deltaT = 1
    oTimer = Timer
    
    
End Sub

