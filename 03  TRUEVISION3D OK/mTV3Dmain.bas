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

    fMain.Show

End Sub
Public Sub EXITTV3D()
    Set surface = Nothing
    Set Shader = Nothing
    Set Scene = Nothing
    Set TV = Nothing

End Sub
'
'
Public Sub MAINLOOP()

    Dim T0!, T1!, T2!, T3!

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



        T0 = Timer
        T1 = T0 - Int(T0)
        T2 = Int(T0) / 10
        T3 = Int(T1) / 10

        Shader.SetEffectParamFloat "TIME1", T1
        Shader.SetEffectParamFloat "TIME2", T2
        Shader.SetEffectParamFloat "TIME3", T3


        DoEvents
    Loop While True

End Sub
'
'
'
'

