Attribute VB_Name = "mDX"
Option Explicit
Public dxSHADER As cDXShader

Public CamMode As Long
Public oTimer As Double
Public deltaT As Double

Private CAMPOS As D3DVECTOR
Private CAMLOOKAT As D3DVECTOR
Private CAMUP As D3DVECTOR

Private Function Mix3(a As D3DVECTOR, b As D3DVECTOR, V As Double) As D3DVECTOR
    Dim V2#
    V2 = 1# - V
    With Mix3
        .X = a.X * V2 + b.X * V
        .Y = a.Y * V2 + b.Y * V
        .Z = a.Z * V2 + b.Z * V
    End With
End Function
Private Function D3DVec(X As Double, Y As Double, Z As Double) As D3DVECTOR
D3DVec.X = X
D3DVec.Y = Y
D3DVec.Z = Z

End Function






Public Sub DoCamera()
    Dim X#, Y#, Z#
Dim T#


T = Timer
    Select Case CamMode


    Case 0

        CAMUP = Mix3(CAMUP, D3DVec(0, 1, 0), deltaT * 0.01)
        CAMLOOKAT = Mix3(CAMLOOKAT, D3DVec(0, 0, 0), deltaT * 0.01)
        X = 500 * Cos(T * 0.1)
        Z = 500 * Sin(T * 0.1)
        CAMPOS = Mix3(CAMPOS, D3DVec(X, 120, Z), deltaT * 0.01)

    Case 1

        X = 200 * Cos(T * 0.17) + 200 * Sin(T * 0.13)
        Z = 200 * Sin(T * 0.17) + 200 * Cos(T * 0.13)
        CAMPOS = Mix3(CAMPOS, D3DVec(X, 120, Z), deltaT * 0.025)

        X = 200 * Cos(T * 0.07) + 200 * Sin(T * 0.09)
        Z = 200 * Sin(T * 0.07) + 200 * Cos(T * 0.09)
        CAMLOOKAT = Mix3(CAMLOOKAT, D3DVec(X, -200, Z), deltaT * 0.025)




    End Select


End Sub

Public Sub SetShaderVariables()
Dim V As D3DVECTOR


'        dxSHADER.SetVariableFloat3 dxSHADER.getRegisterNum("TIME1"), V

    dxSHADER.SetVariableFloat3 dxSHADER.getRegisterNum("CAMPOS"), CAMPOS
    dxSHADER.SetVariableFloat3 dxSHADER.getRegisterNum("CAMLOOKAT"), CAMLOOKAT
    dxSHADER.SetVariableFloat3 dxSHADER.getRegisterNum("CAMUP"), CAMUP

V.X = Timer

    dxSHADER.SetVariableFloat3 dxSHADER.getRegisterNum("TIME1"), V
End Sub


