Attribute VB_Name = "mTV3Dmain"
' - Roberto Mior
' - reexre

Option Explicit

Public TV         As TVEngine

Public Shader     As TVShader
Public Scene      As TVScene
Public Screen2D   As TVScreen2DImmediate
Public surface    As TVRenderSurface
Public texture    As Long

Public SH         As Single
Public SW         As Single
Public AR         As Single


Public Sub INITTV3D()

    Set TV = New TVEngine
    'TV.SetDebugFile App.Path & "\Debug.log"

    TV.DisplayFPS True
    TV.SetDebugFile App.Path & "\logtv3d.txt"
    TV.SetDebugMode (True)
    TV.Init3DWindowed fMain.hWnd

    TV.SetWatermarkParameters TV3D65.CONST_TV_WATERMARKPLACE.TV_WATERMARK_BOTTOMRIGHT, 0.5
    TV.SetVSync False
    TV.ShowWinCursor True

    Set Scene = New TVScene
    'Set Mesh = Scene.CreateMeshBuilder()
    Set Screen2D = New TVScreen2DImmediate

    Set surface = Scene.CreateRenderSurface(512, 512)
    texture = surface.GetTexture
    Set Shader = Scene.CreateShader

    If Not Shader.CreateFromEffectFile(App.Path & "\Shaders.hlsl") Then MsgBox Shader.GetLastError

    Shader.SetTechnique "PostProcess"

    '        Open App.Path & "\Disassembled.HTML" For Output As 1
    '        Print #1, Shader.GetDisassembledEffect(True)
    '        Close 1
    Open App.Path & "\Disassembled.TXT" For Output As 1
    Print #1, Shader.GetDisassembledEffect(False)
    Close 1

    fMain.Show

End Sub
Public Sub EXITTV3D()
    Set surface = Nothing
    Shader.Destroy
    Set Shader = Nothing
    Set Scene = Nothing
    Set TV = Nothing

End Sub
'
'
Public Sub MAINLOOP()


'http://www.truevision3d.com/forums/shader_development/render_a_shader_to_a_texture-t16924.0.html
    Do

        TV.Clear True
        Screen2D.Action_Begin2D
        Screen2D.Draw_FullscreenQuadWithShader Shader, -1, 1 * AR, 1, -1 * AR    '[opt. texture]
        Screen2D.Action_End2D
        TV.RenderToScreen

        ' Outside TV cycle
        surface.StartRender True
        surface.EndRender

        Shader.SetEffectParamFloat "TIME1", CSng(2 * Timer * 0.6)
        

        DoEvents
    Loop While True

End Sub
'
'
'
'

