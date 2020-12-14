VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   9570
   ClientLeft      =   105
   ClientTop       =   450
   ClientWidth     =   10215
   LinkTopic       =   "Form1"
   ScaleHeight     =   638
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   681
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

#Const DebugBuild = True

Private Const ERROR_FILE_NOT_FOUND                      As Long = 2
Private Const LNG_FACILITY_WIN32                        As Long = &H80070000

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)
Private Declare Function lstrlen Lib "kernel32" Alias "lstrlenA" (ByVal lpString As Long) As Long
Private Declare Function GetClientRect Lib "user32" (ByVal hWnd As Long, lpRect As D3D11_RECT) As Long
Private Declare Function GetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" (ByVal lpModuleName As String) As Long
'--- GDI+
Private Declare Function GdiplusStartup Lib "gdiplus" (hToken As Long, pInputBuf As Any, Optional ByVal pOutputBuf As Long = 0) As Long
Private Declare Function GdipLoadImageFromFile Lib "gdiplus" (ByVal sFilename As Long, hImage As Long) As Long
Private Declare Function GdipDisposeImage Lib "gdiplus" (ByVal hImage As Long) As Long
Private Declare Function GdipBitmapLockBits Lib "gdiplus" (ByVal hBitmap As Long, lpRect As Any, ByVal lFlags As Long, ByVal lPixelFormat As Long, uLockedBitmapData As BitmapData) As Long
Private Declare Function GdipBitmapUnlockBits Lib "gdiplus" (ByVal hBitmap As Long, uLockedBitmapData As BitmapData) As Long

Private Type BitmapData
    Width               As Long
    Height              As Long
    Stride              As Long
    PixelFormat         As Long
    Scan0               As Long
    Reserved            As Long
End Type

Private m_d3d11Device           As ID3D11Device1
Private m_d3d11DeviceContext    As ID3D11DeviceContext1
Private m_d3d11SwapChain        As IDXGISwapChain1
Private m_d3d11FrameBufferView  As ID3D11RenderTargetView
Private m_vsBlob                As ID3DBlob
Private m_vertexShader          As ID3D11VertexShader
Private m_pixelShader           As ID3D11PixelShader
Private m_inputLayout           As ID3D11InputLayout
Private m_vertexBuffer          As ID3D11Buffer
Private m_numVerts              As Long
Private m_stride                As Long
Private m_offset                As Long
Private m_samplerState          As ID3D11SamplerState
Private m_textureView           As ID3D11ShaderResourceView
Private m_isRunning             As Boolean
Private m_windowDidResize       As Boolean

Private Type UcsBuffer
    Data()              As Byte
End Type

Private Sub Form_Load()
    Dim hResult         As VBHRESULT
    
    '--- Create D3D11 Device and Context
    Dim featureLevels() As Long
    Dim creationFlags   As Long
    pvArrayLong featureLevels, D3D_FEATURE_LEVEL_11_0
    creationFlags = D3D11_CREATE_DEVICE_BGRA_SUPPORT
    #If DebugBuild Then
        creationFlags = creationFlags Or D3D11_CREATE_DEVICE_DEBUG
    #End If
RetryCreateDevice:
    hResult = D3D11CreateDevice(Nothing, D3D_DRIVER_TYPE_HARDWARE, 0, creationFlags, _
                                featureLevels(0), UBound(featureLevels) + 1, D3D11_SDK_VERSION, _
                                m_d3d11Device, 0, m_d3d11DeviceContext)
    If hResult = DXGI_ERROR_SDK_COMPONENT_MISSING And (creationFlags And D3D11_CREATE_DEVICE_DEBUG) <> 0 Then
        creationFlags = creationFlags And Not D3D11_CREATE_DEVICE_DEBUG
        GoTo RetryCreateDevice
    End If
    If hResult < 0 Then
        Err.Raise hResult, "D3D11CreateDevice"
    End If
    
#If DebugBuild And False Then
    '--- Set up debug layer to break on D3D11 errors
    Dim d3dDebug        As ID3D11Debug
    Dim d3dInfoQueue    As ID3D11InfoQueue
    Set d3dDebug = m_d3d11Device
    If Not d3dDebug Is Nothing Then
        Set d3dInfoQueue = d3dDebug
        d3dInfoQueue.SetBreakOnSeverity D3D11_MESSAGE_SEVERITY_CORRUPTION, 1
        d3dInfoQueue.SetBreakOnSeverity D3D11_MESSAGE_SEVERITY_ERROR, 1
        Set d3dInfoQueue = Nothing
    End If
    Set d3dDebug = Nothing
#End If
    
    '--- Create Swap Chain
    Dim dxgiFactory     As IDXGIFactory2
    Dim dxgiDevice      As IDXGIDevice1
    Dim dxgiAdapter     As IDXGIAdapter
    Dim adapterDesc     As DXGI_ADAPTER_DESC
    Dim d3d11SwapChainDesc As DXGI_SWAP_CHAIN_DESC1
    Set dxgiDevice = m_d3d11Device
    Set dxgiAdapter = dxgiDevice.GetAdapter()
    Set dxgiDevice = Nothing
    dxgiAdapter.GetDesc adapterDesc
    Debug.Print "Graphics Device: " & Replace(adapterDesc.Description, vbNullChar, vbNullString)
    Set dxgiFactory = dxgiAdapter.GetParent(IIDFromString(szIID_IDXGIFactory2))
    With d3d11SwapChainDesc
        .Width = 0 '--- use window width
        .Height = 0 '--- use window height
        .Format = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB
        .SampleDesc.Count = 1
        .SampleDesc.Quality = 0
        .BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT
        .BufferCount = 2
        .Scaling = DXGI_SCALING_STRETCH
        .SwapEffect = DXGI_SWAP_EFFECT_DISCARD
        .AlphaMode = DXGI_ALPHA_MODE_UNSPECIFIED
        .Flags = 0
    End With
    Set m_d3d11SwapChain = dxgiFactory.CreateSwapChainForHwnd(m_d3d11Device, hWnd, d3d11SwapChainDesc, ByVal 0, Nothing)
    
    '--- Create Framebuffer Render Target
    Dim d3d11FrameBuffer As ID3D11Texture2D
    Set d3d11FrameBuffer = m_d3d11SwapChain.GetBuffer(0, IIDFromString(szIID_ID3D11Texture2D))
    Set m_d3d11FrameBufferView = m_d3d11Device.CreateRenderTargetView(d3d11FrameBuffer, ByVal 0)
    Set d3d11FrameBuffer = Nothing
    
    '--- Create Vertex Shader
    Dim shaderCompileErrorsBlob As ID3DBlob
    Dim errorString     As String
    hResult = D3DCompileFromFile(PathCombine(App.Path, "shaders.hlsl"), ByVal 0, ByVal 0, "vs_main", "vs_5_0", 0, 0, m_vsBlob, shaderCompileErrorsBlob)
    If hResult < 0 Then
        If hResult = LNG_FACILITY_WIN32 Or ERROR_FILE_NOT_FOUND Then
            errorString = "Could not compile VERTEX shader; file not found"
        ElseIf Not shaderCompileErrorsBlob Is Nothing Then
            errorString = pvToString(shaderCompileErrorsBlob.GetBufferPointer())
        End If
        MsgBox errorString, vbCritical, "Shader Compiler Error"
        Unload Me
        GoTo QH
    End If
    Set m_vertexShader = m_d3d11Device.CreateVertexShader(m_vsBlob.GetBufferPointer(), m_vsBlob.GetBufferSize(), Nothing)
    
    '--- Create Pixel Shader
    Dim psBlob As ID3DBlob
    hResult = D3DCompileFromFile(PathCombine(App.Path, "shaders.hlsl"), ByVal 0, ByVal 0, "ps_main", "ps_5_0", 0, 0, psBlob, shaderCompileErrorsBlob)
    If hResult < 0 Then
        If hResult = LNG_FACILITY_WIN32 Or ERROR_FILE_NOT_FOUND Then
            errorString = "Could not compile PIXEL shader; file not found"
        ElseIf Not shaderCompileErrorsBlob Is Nothing Then
            errorString = pvToString(shaderCompileErrorsBlob.GetBufferPointer())
        End If
        MsgBox errorString, vbExclamation, "Shader Compiler Error"
        Unload Me
        GoTo QH
    End If
    Set m_pixelShader = m_d3d11Device.CreatePixelShader(psBlob.GetBufferPointer(), psBlob.GetBufferSize(), Nothing)
    Set psBlob = Nothing
    
    '--- Create Input Layout
    Dim inputElementDesc(0 To 1)  As D3D11_INPUT_ELEMENT_DESC
    Dim nameBuffer(0 To 1) As UcsBuffer
    pvInitInputElementDesc inputElementDesc(0), nameBuffer(0), "POS", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0
    pvInitInputElementDesc inputElementDesc(1), nameBuffer(1), "TEX", 0, DXGI_FORMAT_R32G32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA, 0
     
    'Messo io
'    pvInitInputElementDesc inputElementDesc(2), nameBuffer(2), "TEXCOORD1", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA, 0
        
    Set m_inputLayout = m_d3d11Device.CreateInputLayout(inputElementDesc(0), UBound(inputElementDesc) + 1, m_vsBlob.GetBufferPointer(), m_vsBlob.GetBufferSize())
    
    '--- Create Vertex Buffer
    Dim vertexData() As Single '--- x, y, u, v
'    pvArraySingle vertexData, _
        -0.5!, 0.5!, 0!, 0!, _
        0.5!, -0.5!, 1!, 1!, _
        -0.5!, -0.5!, 0!, 1!, _
        -0.5!, 0.5!, 0!, 0!, _
        0.5!, 0.5!, 1!, 0!, _
        0.5!, -0.5!, 1!, 1!
        
' For RayMarching
    pvArraySingle vertexData, _
        -1!, 1!, -1!, 1!, _
        1!, -1!, 1!, -1!, _
        -1!, -1!, -1!, -1!, _
        -1!, 1!, -1!, 1!, _
        1!, 1!, 1!, 1!, _
        1!, -1!, 1!, -1!
        
    m_stride = 4 * 4
    m_numVerts = (UBound(vertexData) + 1) / 4
    m_offset = 0
    Dim vertexBufferDesc As D3D11_BUFFER_DESC
    With vertexBufferDesc
        .ByteWidth = (UBound(vertexData) + 1) * 4
        .Usage = D3D11_USAGE_IMMUTABLE
        .BindFlags = D3D11_BIND_VERTEX_BUFFER
    End With
    Dim vertexSubresourceData As D3D11_SUBRESOURCE_DATA
    vertexSubresourceData.pSysMem = VarPtr(vertexData(0))
    Set m_vertexBuffer = m_d3d11Device.CreateBuffer(vertexBufferDesc, vertexSubresourceData)
    
    '--- Create Sampler State
    Dim samplerDesc As D3D11_SAMPLER_DESC
    With samplerDesc
        .Filter = D3D11_FILTER_MIN_MAG_MIP_POINT
        .AddressU = D3D11_TEXTURE_ADDRESS_BORDER
        .AddressV = D3D11_TEXTURE_ADDRESS_BORDER
        .AddressW = D3D11_TEXTURE_ADDRESS_BORDER
        .BorderColor(0) = 1!
        .BorderColor(1) = 1!
        .BorderColor(2) = 1!
        .BorderColor(3) = 1!
        .ComparisonFunc = D3D11_COMPARISON_NEVER
    End With
    Set m_samplerState = m_d3d11Device.CreateSamplerState(samplerDesc)
    
    '--- Load Image
    Dim texWidth         As Long
    Dim texHeight        As Long
    Dim texNumChannels   As Long
    Dim testTextureBytes() As Byte
    Dim texBytesPerRow   As Long
    If Not pvLoadPng(PathCombine(App.Path, "testTexture.png"), texWidth, texHeight, texNumChannels, testTextureBytes) Then
        MsgBox "Error loading testTexture.png", vbExclamation, "Load Image"
        Unload Me
        GoTo QH
    End If
    texBytesPerRow = texWidth * texNumChannels
    
    '--- Create Texture
    Dim textureDesc     As D3D11_TEXTURE2D_DESC
    Dim textureSubresourceData As D3D11_SUBRESOURCE_DATA
    Dim texture         As ID3D11Texture2D
    With textureDesc
        .Width = texWidth
        .Height = texHeight
        .MipLevels = 1
        .ArraySize = 1
        .Format = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB
        .SampleDesc.Count = 1
        .Usage = D3D11_USAGE_IMMUTABLE
        .BindFlags = D3D11_BIND_SHADER_RESOURCE
    End With
    With textureSubresourceData
        .pSysMem = VarPtr(testTextureBytes(0))
        .SysMemPitch = texBytesPerRow
    End With
    Set texture = m_d3d11Device.CreateTexture2D(textureDesc, textureSubresourceData)
    Set m_textureView = m_d3d11Device.CreateShaderResourceView(texture, ByVal 0)
    
    '--- Main Loop
    Show
    m_isRunning = True
    Do While m_isRunning
        If m_windowDidResize Then
            m_d3d11DeviceContext.OMSetRenderTargets 0, Nothing, Nothing
            Set m_d3d11FrameBufferView = Nothing
            m_d3d11SwapChain.ResizeBuffers 0, 0, 0, DXGI_FORMAT_UNKNOWN, 0
            Set d3d11FrameBuffer = m_d3d11SwapChain.GetBuffer(0, IIDFromString(szIID_ID3D11Texture2D))
            Set m_d3d11FrameBufferView = m_d3d11Device.CreateRenderTargetView(d3d11FrameBuffer, ByVal 0)
            Set d3d11FrameBuffer = Nothing
            m_windowDidResize = False
        End If
        
        Dim backgroundColor() As Single
        pvArraySingle backgroundColor, 0.1!, 0.2!, 0.6!, 1!
        m_d3d11DeviceContext.ClearRenderTargetView m_d3d11FrameBufferView, backgroundColor(0)
        
        Dim winRect As D3D11_RECT
        Call GetClientRect(hWnd, winRect)
        Dim viewport As D3D11_VIEWPORT
        With viewport
            .Width = winRect.Right - winRect.Left
            .Height = winRect.Bottom - winRect.Top
            .MaxDepth = 1
        End With
        m_d3d11DeviceContext.RSSetViewports 1, viewport
        
        m_d3d11DeviceContext.OMSetRenderTargets 1, m_d3d11FrameBufferView, Nothing
        
        m_d3d11DeviceContext.IASetPrimitiveTopology D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST
        m_d3d11DeviceContext.IASetInputLayout m_inputLayout
        
        m_d3d11DeviceContext.VSSetShader m_vertexShader, Nothing, 0
        m_d3d11DeviceContext.PSSetShader m_pixelShader, Nothing, 0
        
        m_d3d11DeviceContext.PSSetShaderResources 0, 1, m_textureView
        m_d3d11DeviceContext.PSSetSamplers 0, 1, m_samplerState
        
        m_d3d11DeviceContext.IASetVertexBuffers 0, 1, m_vertexBuffer, m_stride, m_offset

        m_d3d11DeviceContext.Draw m_numVerts, 0
        
        m_d3d11SwapChain.Present 1, 0
        
        DoEvents
    Loop
QH:
End Sub

Private Sub pvArrayLong(aDest() As Long, ParamArray A() As Variant)
    Dim lIdx            As Long
    
    ReDim aDest(0 To UBound(A)) As Long
    For lIdx = 0 To UBound(A)
        aDest(lIdx) = A(lIdx)
    Next
End Sub

Private Sub pvArraySingle(aDest() As Single, ParamArray A() As Variant)
    Dim lIdx            As Long
    
    ReDim aDest(0 To UBound(A)) As Single
    For lIdx = 0 To UBound(A)
        aDest(lIdx) = A(lIdx)
    Next
End Sub

Private Sub pvInitInputElementDesc(uEntry As D3D11_INPUT_ELEMENT_DESC, uBuffer As UcsBuffer, SemanticName As String, ByVal SemanticIndex As Long, ByVal Format As DXGI_FORMAT, ByVal InputSlot As Long, ByVal AlignedByteOffset As Long, ByVal InputSlotClass As D3D11_INPUT_CLASSIFICATION, ByVal InstanceDataStepRate As Long)
    uBuffer.Data = StrConv(SemanticName & vbNullChar, vbFromUnicode)
    With uEntry
        .SemanticName = VarPtr(uBuffer.Data(0))
        .SemanticIndex = SemanticIndex
        .Format = Format
        .InputSlot = InputSlot
        .AlignedByteOffset = AlignedByteOffset
        .InputSlotClass = InputSlotClass
        .InstanceDataStepRate = InstanceDataStepRate
    End With
End Sub

Private Function pvToString(ByVal lPtr As Long) As String
    If lPtr <> 0 Then
        pvToString = String$(lstrlen(lPtr), 0)
        Call CopyMemory(ByVal pvToString, ByVal lPtr, Len(pvToString))
    End If
End Function

Private Function PathCombine(sPath As String, sFile As String) As String
    PathCombine = sPath & IIf(LenB(sPath) <> 0 And Right$(sPath, 1) <> "\" And LenB(sFile) <> 0, "\", vbNullString) & sFile
End Function

Private Function pvLoadPng(sFilename As String, lWidth As Long, lHeight As Long, lChannels As Long, baData() As Byte) As Boolean
    Const ImageLockModeRead As Long = 1
    Const PixelFormat32bppPARGB As Long = &HE200B
    Dim aInput(0 To 3)  As Long
    Dim hBitmap         As Long
    Dim uData           As BitmapData
    
    If GetModuleHandle("gdiplus") = 0 Then
        aInput(0) = 1
        Call GdiplusStartup(0, aInput(0))
    End If
    If GdipLoadImageFromFile(StrPtr(sFilename), hBitmap) <> 0 Then
        GoTo QH
    End If
    If GdipBitmapLockBits(hBitmap, ByVal 0, ImageLockModeRead, PixelFormat32bppPARGB, uData) <> 0 Then
        GoTo QH
    End If
    lWidth = uData.Width
    lHeight = uData.Height
    lChannels = 4
    ReDim baData(0 To uData.Stride * uData.Height - 1) As Byte
    Call CopyMemory(baData(0), ByVal uData.Scan0, UBound(baData) + 1)
    '--- success
    pvLoadPng = True
QH:
    If uData.Scan0 <> 0 Then
        Call GdipBitmapUnlockBits(hBitmap, uData)
    End If
    If hBitmap <> 0 Then
        Call GdipDisposeImage(hBitmap)
    End If
End Function

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
    m_isRunning = False
End Sub

Private Sub Form_Resize()
    m_windowDidResize = True
End Sub
