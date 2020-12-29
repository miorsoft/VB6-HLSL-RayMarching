VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cDXShader"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' ORIGINAL
'https://github.com/thetrik/DX9VB/tree/main/Demos/Raymarching

Option Explicit

' // Input of vertex shader
Private Type tVertex
    fX            As Single
    fY            As Single
    fU            As Single
    fV            As Single
End Type

Private Declare Function D3DXGetVertexShaderProfile Lib "d3dx9_43" ( _
                                                    ByVal pDevice As IDirect3DDevice9) As Long
Private Declare Function D3DXGetPixelShaderProfile Lib "d3dx9_43" ( _
                                                   ByVal pDevice As IDirect3DDevice9) As Long
Private Declare Function D3DXCreateBuffer Lib "d3dx9_43" ( _
                                          ByVal NumBytes As Long, _
                                          ByRef ppBuffer As ID3DXBuffer) As Long
Private Declare Function D3DXCompileShaderFromFile Lib "d3dx9_43" _
                                                   Alias "D3DXCompileShaderFromFileW" ( _
                                                   ByVal pSrcFile As Long, _
                                                   ByRef pDefines As Any, _
                                                   ByVal pInclude As ID3DXInclude, _
                                                   ByVal pFunctionName As String, _
                                                   ByVal pProfile As Long, _
                                                   ByVal Flags As Long, _
                                                   ByRef ppShader As ID3DXBuffer, _
                                                   ByRef ppErrorMsgs As ID3DXBuffer, _
                                                   ByRef ppConstantTable As ID3DXConstantTable) As Long
Private Declare Function D3DXGetShaderConstantTable Lib "d3dx9_43" ( _
                                                    ByRef pFunction As Any, _
                                                    ByRef ppConstantTable As ID3DXConstantTable) As Long

Private Declare Sub memcpy Lib "kernel32" _
                           Alias "RtlMoveMemory" ( _
                           ByRef Destination As Any, _
                           ByRef Source As Any, _
                           ByVal Length As Long)

Private m_cD3D    As IDirect3D9
Attribute m_cD3D.VB_VarUserMemId = 1879245032
Private m_cDevice As IDirect3DDevice9
Attribute m_cDevice.VB_VarUserMemId = 1073938433
Private m_cQuad   As IDirect3DVertexBuffer9
Private m_lTime1Reg As Single    'Long
Public FPS        As Long

'----------------------------------------------------------

Private tPP       As D3DPRESENT_PARAMETERS
Attribute tPP.VB_VarUserMemId = 1610809344
Private cErrMsg   As ID3DXBuffer
Attribute cErrMsg.VB_VarUserMemId = 1073938439
Private cPSCode   As ID3DXBuffer
Attribute cPSCode.VB_VarUserMemId = 1073938440
Private cVSCode   As ID3DXBuffer
Attribute cVSCode.VB_VarUserMemId = 1073938441
Private cPSConstTbl As ID3DXConstantTable
Attribute cPSConstTbl.VB_VarUserMemId = 1073938442
Private cVShader  As IDirect3DVertexShader9
Attribute cVShader.VB_VarUserMemId = 1073938443
Private cPShader  As IDirect3DPixelShader9
Attribute cPShader.VB_VarUserMemId = 1073938444
Private cVtxDecl  As IDirect3DVertexDeclaration9
Attribute cVtxDecl.VB_VarUserMemId = 1073938445
Private tVertex(5) As tVertex
Attribute tVertex.VB_VarUserMemId = 1073938446
Private tVtxDecl(2) As D3DVERTEXELEMENT9
Attribute tVtxDecl.VB_VarUserMemId = 1073938447
Private pData     As Long
Attribute pData.VB_VarUserMemId = 1073938448
Private hConst    As Long
Attribute hConst.VB_VarUserMemId = 1073938449
Private fAspect   As Single
Attribute fAspect.VB_VarUserMemId = 1073938450
Private hr        As Long
Attribute hr.VB_VarUserMemId = 1073938451

Private m_WW      As Long
Attribute m_WW.VB_VarUserMemId = 1073938452
Private m_WH      As Long
Attribute m_WH.VB_VarUserMemId = 1073938453


Public Sub Init(hWnd As Long, lWidth As Long, lHeight As Long)

    tPP.BackBufferCount = 1
    tPP.Windowed = 1
    tPP.BackBufferFormat = D3DFMT_A8R8G8B8
    tPP.SwapEffect = D3DSWAPEFFECT_DISCARD
    tPP.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE
    Set m_cDevice = m_cD3D.CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, tPP)
    '----------------------------
    m_WW = lWidth
    m_WH = lHeight

End Sub


Public Sub PreLaunch()
    m_lTime1Reg = pvGetShaderConstantRegister(cPSConstTbl, "TIME1")

    ' // Create shaders
    Set cVShader = m_cDevice.CreateVertexShader(ByVal cVSCode.GetBufferPointer)
    Set cPShader = m_cDevice.CreatePixelShader(ByVal cPSCode.GetBufferPointer)

    ' // Create vertex declaration
    tVtxDecl(0) = vtx_element(0, 0, D3DDECLTYPE_FLOAT2, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_POSITION, 0)
    tVtxDecl(1) = vtx_element(0, 8, D3DDECLTYPE_FLOAT2, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_TEXCOORD, 0)
    tVtxDecl(2) = D3DDECL_END

    Set cVtxDecl = m_cDevice.CreateVertexDeclaration(tVtxDecl(0))

    m_cDevice.SetVertexDeclaration cVtxDecl

    ' // Create full-screen quad based on screen aspect ration
    fAspect = m_WH / m_WW

    tVertex(0) = vtx(-1, 1, -1, fAspect)
    tVertex(1) = vtx(1, -1, 1, -fAspect)
    tVertex(2) = vtx(1, 1, 1, fAspect)

    tVertex(3) = vtx(-1, 1, -1, fAspect)
    tVertex(4) = vtx(1, -1, 1, -fAspect)
    tVertex(5) = vtx(-1, -1, -1, -fAspect)

    ' // Create vertex buffer with quad data
    m_cDevice.CreateVertexBuffer Len(tVertex(0)) * (UBound(tVertex) + 1), 0, 0, 0, m_cQuad

    m_cQuad.Lock 0, Len(tVertex(0)) * (UBound(tVertex) + 1), pData, 0
    memcpy ByVal pData, tVertex(0), Len(tVertex(0)) * (UBound(tVertex) + 1)
    m_cQuad.Unlock

    m_cDevice.SetStreamSource 0, m_cQuad, 0, Len(tVertex(0))

    ' // Disable culling
    m_cDevice.SetRenderState D3DRS_CULLMODE, D3DCULL_NONE

    ' // Set shaders to device
    m_cDevice.SetPixelShader cPShader
    m_cDevice.SetVertexShader cVShader
End Sub

Public Sub CompileFromFile(FN As String, IsPixelS As Long, Optional SaveBin As Boolean = True)

' // Compile vertex shader code
    If Not (IsPixelS) Then
        hr = D3DXCompileShaderFromFile(StrPtr(FN), ByVal 0&, Nothing, "vs_main", _
                                       StrPtr(StrConv("vs_1_1", vbFromUnicode)), 0, cVSCode, cErrMsg, Nothing)
        If hr < 0 Then
            pvShowCompError cErrMsg
            Exit Sub
        Else
            Set cErrMsg = Nothing
        End If

        If SaveBin Then pvSaveShaderToFile cVSCode, pvRemoveExtension(FN) & ".BIN"
    Else
        ' // Compile pixel shader code
        hr = D3DXCompileShaderFromFile(StrPtr(FN), ByVal 0&, Nothing, "ps_main", _
                                       StrPtr(StrConv("ps_3_0", vbFromUnicode)), 0, cPSCode, cErrMsg, cPSConstTbl)
        If hr < 0 Then
            pvShowCompError cErrMsg
            Exit Sub
        End If

        If SaveBin Then pvSaveShaderToFile cPSCode, pvRemoveExtension(FN) & ".BIN"

    End If

End Sub

Public Sub LoadFromBinVS(FN As String)
    Set cVSCode = pvLoadShaderFromFile(FN)    'App.Path & "\vs.bin")
    If hr < 0 Then
        Err.Raise hr
    End If
End Sub
Public Sub LoadFromBinPS(FN As String)
    Set cPSCode = pvLoadShaderFromFile(FN)    'App.Path & "\ps.bin")
    hr = D3DXGetShaderConstantTable(ByVal cPSCode.GetBufferPointer, cPSConstTbl)
    If hr < 0 Then
        Err.Raise hr
    End If
End Sub


Private Function pvRemoveExtension(S As String) As String
    pvRemoveExtension = Left$(S, InStrRev(S, ".") - 1)
End Function


' // Show error message storred to ID3DXBuffer buffer
Private Sub pvShowCompError( _
        ByVal cErrMsg As ID3DXBuffer)
    Dim bAnsiInfo() As Byte
    Dim sMsgUnicode As String

    If cErrMsg.GetBufferSize > 0 Then

        ReDim bAnsiInfo(cErrMsg.GetBufferSize - 1)

        memcpy bAnsiInfo(0), ByVal cErrMsg.GetBufferPointer, UBound(bAnsiInfo) + 1

        sMsgUnicode = StrConv(bAnsiInfo, vbUnicode)

        MsgBox sMsgUnicode, vbCritical

    Else
        MsgBox "Unknown error", vbCritical
    End If

End Sub
' // Save binary shader to file
Private Sub pvSaveShaderToFile( _
        ByVal cShader As ID3DXBuffer, _
        ByRef sFileName As String)
    Dim iFile     As Integer
    Dim bData()   As Byte

    If Len(Dir(sFileName)) Then
        Kill sFileName
    End If

    iFile = FreeFile

    Open sFileName For Binary As iFile
    If cShader.GetBufferSize > 0 Then

        ReDim bData(cShader.GetBufferSize - 1)
        memcpy bData(0), ByVal cShader.GetBufferPointer, UBound(bData) + 1

        Put iFile, , bData

    End If
    Close iFile
End Sub

Private Sub Class_Initialize()
    Set m_cD3D = Direct3DCreate9()
End Sub
Private Sub Class_Terminate()
    Set m_cQuad = Nothing
    Set m_cDevice = Nothing
    Set m_cD3D = Nothing
End Sub


' // Get register index of shader constant
Private Function pvGetShaderConstantRegister( _
        ByVal cTable As ID3DXConstantTable, _
        ByVal sName As String) As Long
    Dim hConst    As Long
    Dim tDesc     As D3DXCONSTANT_DESC

    hConst = cTable.GetConstantByName(0, sName)
    If hConst = 0 Then
        Err.Raise 5
    End If

    cTable.GetConstantDesc hConst, tDesc, 1

    pvGetShaderConstantRegister = tDesc.RegisterIndex
End Function


' // Create D3DVERTEXELEMENT9 ittem
Private Function vtx_element( _
        ByVal lStream As Long, _
        ByVal lOffset As Long, _
        ByVal eType As D3DDECLTYPE, _
        ByVal eMethod As D3DDECLMETHOD, _
        ByVal eUsage As D3DDECLUSAGE, _
        ByVal lUsageIndex As Long) As D3DVERTEXELEMENT9

    With vtx_element
        .Stream = lStream
        .Offset = lOffset
        .Type = eType
        .Method = eMethod
        .Usage = eUsage
        .UsageIndex = lUsageIndex
    End With

End Function

' // Create vertex
Private Function vtx( _
        ByVal fX As Single, _
        ByVal fY As Single, _
        ByVal fU As Single, _
        ByVal fV As Single) As tVertex
    vtx.fX = fX
    vtx.fY = fY
    vtx.fU = fU
    vtx.fV = fV
End Function
Private Function D3DDECL_END() As D3DVERTEXELEMENT9
    D3DDECL_END = vtx_element(255, 0, D3DDECLTYPE_UNUSED, 0, 0, 0)
End Function

' // Load binary shader from file
Private Function pvLoadShaderFromFile( _
        ByRef sFileName As String) As ID3DXBuffer
    Dim iFile     As Integer
    Dim bData()   As Byte
    Dim lSize     As Long
    Dim cRet      As ID3DXBuffer
    Dim hr        As Long

    iFile = FreeFile

    Open sFileName For Binary As iFile

    lSize = LOF(iFile)

    If lSize <= 0 Then
        Err.Raise 5
    End If

    ReDim bData(lSize - 1)

    Get iFile, , bData

    Close iFile

    hr = D3DXCreateBuffer(lSize, cRet)

    If hr < 0 Then
        Err.Raise hr
    End If

    memcpy ByVal cRet.GetBufferPointer, bData(0), UBound(bData) + 1

    Set pvLoadShaderFromFile = cRet

End Function

Public Sub RENDER()
' be sure to call PreLaunch first
    m_cDevice.SetPixelShaderConstantF m_lTime1Reg, CSng(2 * Timer * 0.6), 1
    m_cDevice.BeginScene
    ' // Draw full-scree quad
    m_cDevice.DrawPrimitive D3DPT_TRIANGLELIST, 0, 2
    m_cDevice.EndScene
    m_cDevice.Present ByVal 0&, ByVal 0&, 0, ByVal 0&
    FPS = FPS + 1
End Sub



