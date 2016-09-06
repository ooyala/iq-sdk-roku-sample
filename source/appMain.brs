
Sub Main()

    'CUSTOM DATA FOR THE SAMPLE APP. PUT YOUR INFO HERE
    m.API_KEY = "BmeGYyOpSplhQQLevgeb76wbvwXz.kdWu_"
    m.SECRET = "TeX-ZMrpm1SIJmRlDY8blCDGyu0NnyuNtL3ikbVr"
    m.PREFIX = "" 'ONLY THE VIDEOS WITH THE SELECTED PREFIX WILL SHOW UP ON THE SCREEN
    m.PCODE = "BmeGYyOpSplhQQLevgeb76wbvwXz"
    m.STREAM_FORMAT = "MP4" 'MP4 or TS for HLS

    'initialize theme attributes like titles, logos and overhang color
    initTheme()
    'Create an instance of Ooyala IQ and initialize it
    m.iq = IQ()
    showGridScreen()
    'exit the app gently so that the screen doesn't flash to black
    screenFacade.showMessage("")
    sleep(25)
End Sub

Sub showGridScreen()
    userInfo = {}
    geoInfo = {}
    ageGroup ={min : 25, max : 30}

    userInfo.AddReplace("emailHashMD5", "dc250da0315f62bbb94ea5a2dff76755")
    userInfo.AddReplace("userId", "Alex")
    userInfo.AddReplace("gender", "M")
    userInfo.AddReplace("ageGroup", ageGroup)

    geoInfo.AddReplace("countryCode", "US")
    geoInfo.AddReplace("region", "CA")
    geoInfo.AddReplace("city", "SANTACLARA")
    geoInfo.AddReplace("latitude", 37.399092)
    geoInfo.AddReplace("longitude", -121.985771)
    geoInfo.AddReplace("geoVendor", "akamai")

    m.iq.init(m.PCODE) 'Session init
    m.iq.setUserInfo(userInfo)
    m.iq.setGeoInfo(geoInfo)

    listScreen = CreateObject("roGridScreen")
    listScreen.setupLists(3)
    listScreen.setListNames(["Backlot assets", "Backlot remote assets", "Non backlot"])
    port = CreateObject("roMessagePort")
    listScreen.setMessagePort(port)
    'Get the items from Backlot
    assets = GetBacklotData(m.API_KEY, m.SECRET, m.PREFIX)
    'Add our non backlot asset
    nonBacklotAssets = getNonBacklotAssets()
    assetList = []
    assetList.push(makeAssetListFromBacklotAssets(assets[0]))
    assetList.push(makeAssetListFromRemoteAssets(assets[1]))
    assetList.push(nonBacklotAssets)

    listScreen.setContentList(0, assetList[0])
    listScreen.setContentList(1, assetList[1])
    listScreen.setContentList(2, assetList[2])
    listScreen.show()

    while True
        msg = wait(0, listScreen.GetMessagePort())
        if type(msg) = "roGridScreenEvent"
            if msg.isListItemSelected()
                if(msg.GetIndex() < 2)
                    playAsset(assetList[msg.GetIndex()][msg.GetData()], assets[msg.GetIndex()][msg.GetData()])
                else
                    playAsset(assetList[msg.GetIndex()][msg.GetData()], invalid)
                end if
            end if
        end if
    end While
End SUB


Function getNonBacklotAssets() as Object
    asset = {}
    asset.StreamBitrates  = [0]    
    asset.StreamUrls = ["http://pulse-demo.cdn.videoplaza.tv/resources/media/sintel_trailer_854x480.mp4"]
    asset.StreamQualities = ["HD"]
    asset.length = 53
    asset.HDPosterUrl = "https://upload.wikimedia.org/wikipedia/commons/8/8f/Sintel_poster.jpg"
    asset.StreamFormat = "mp4"
    asset.title = "Sintel Trailer"
    asset.assetId = "42"
    return [asset]
End function

Function playAsset(asset as Object, backlotAsset as Object)
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    'Load video content
    videoclip = {}
    videoclip.StreamBitrates = asset.StreamBitrates
    videoclip.StreamUrls = asset.StreamUrls
    videoclip.StreamQualities = asset.StreamQualities

    if(asset.ForceHLS = true)
        videoclip.StreamFormat = "hls"
    elseif(m.STREAM_FORMAT = "MP4")
        videoclip.StreamFormat = "mp4"
    else
        videoclip.StreamFormat = "hls"
    end if

    videoclip.title = asset.Title
    
    'Assign videocontent to video screen Object
    video.SetContent(videoclip)
    'Provide content metadata to IQ plugin
    if(backlotAsset <> invalid)
        assetId = backlotAsset.embedCode
        assetType = "ooyala"
    else
        print "asset id "; asset.assetId
        assetId = asset.assetId
        assetType = "external"
    end if
    m.iq.setContentMetadata({duration : asset.length, assetId : assetId , assetType: assetType})
    video.SetPositionNotificationPeriod(1)'DO NOT FORGET TO ADD THIS FOR GOOD PLAYHEAD UPDATE
    
    'Start video screen playback
    video.show()
    'Report to IQ about playback request
    m.iq.reportPlayRequested(false)

    lastSavedPos   = 0
    statusInterval = 10 'position must change by more than this number of seconds before saving
    while true
        msg = wait(1000, video.GetMessagePort())
        m.iq.handleEvent(msg)
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 10000
                    
                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while
    m.iq.reportEventLoopExit()
End function



Function makeAssetListFromBacklotAssets(assets as Object)
    assetList = []
    For each asset in assets
        contentItem = {}
        streams = getStreamsForEmbedCode(asset.embedCode)
        contentItem.AddReplace("Title", asset.name)
        contentItem.AddReplace("Length", asset.duration/1000)
        contentItem.AddReplace("HDPosterUrl", asset.posterURL)
        contentItem.AddReplace("StreamUrls", streams.urls)
        contentItem.AddReplace("StreamBitrates", streams.bitrates)
        contentItem.AddReplace("StreamQualities", streams.qualities)
        assetList.push(contentItem)
    end for
    return assetList
End Function

Function makeAssetListFromRemoteAssets(assets as Object)
    assetList = []
    For each asset in assets
        contentItem = {}
        contentItem.AddReplace("Title", asset.name)
        contentItem.AddReplace("Length", asset.duration/1000)
        contentItem.AddReplace("HDPosterUrl", asset.posterURL)
        contentItem.AddReplace("StreamUrls", [asset.stream])
        contentItem.AddReplace("StreamBitrates", [0])
        contentItem.AddReplace("StreamQualities", ["HD"])
        if asset.is_live
            contentItem.AddReplace("ForceHLS", true)
        end if
        assetList.push(contentItem)
    end for
    return assetList
End Function


Function getStreamsForEmbedCode(embedCode as String) as Object
    route = box("/v2/assets/")
    route.appendString(embedCode, embedCode.len())
    route.appendString("/streams", 8)
    print "Getting streams for "; embedCode
    streamsJSON = makeBacklotRequest(m.API_KEY, m.SECRET,route)
    streams = {}
    streams.urls =[]
    streams.bitrates =[]
    streams.qualities = []
    For Each stream in streamsJSON
        if (Type(stream) <> "roString")
            if (stream.muxing_format.Instr(m.STREAM_FORMAT) <> -1)
                print "Using stream url ";stream.url
                streams.urls.push(stream.url)
                streams.bitrates.push(stream.average_video_bitrate)
                streams.qualities.push("HD")
            end if
        end if
    End For
    return streams
End Function


Function makeBacklotRequest(apiKey as String, secret as String, route as String)
    backlotUrl = box("https://api.ooyala.com")
    backlotUrl.appendString(route,route.len())

    addParamToQuery(backlotUrl,"expires","1999991855")
    addParamToQuery(backlotUrl,"api_key",apiKey)
    signature = generateSignature(apiKey, secret, route)
    addParamToQuery(backlotUrl,"signature",signature)
    urlReq = CreateObject("roUrlTransfer")

    urlReq.SetUrl(backlotUrl)
    urlReq.RetainBodyOnError(true)
    urlReq.EnablePeerVerification(false)
    urlReq.EnableHostVerification(false)
    resp = urlReq.GetToString()
    return ParseJSON(resp)
End Function

Function GetBacklotData(API_KEY as String,SECRET as String, prefix as String) as Object
    route = "/v2/assets"
    assetsJSON = makeBacklotRequest(API_KEY,SECRET,route)
    assets = getAssetsListsFromJSON(assetsJSON, prefix)
    return assets
End Function


Function getAssetsListsFromJSON( json as Object, prefix as String) as  Object
    assets = []
    backlot = []
    remote = []

    For each item in json.items
        if (item.asset_type <> Invalid)
            if(item.name.Instr(prefix) <> -1)
                if(item.asset_type = "video")   
                    asset = {}
                    asset.AddReplace("embedCode", item.embed_code)
                    asset.AddReplace("duration", item.duration)
                    asset.AddReplace("name", item.name)
                    asset.AddReplace("posterURL", item.preview_image_url)
                    backlot.push(asset)   
                else if (item.asset_type = "remote_asset")
                    asset = {}
                    asset.AddReplace("embedCode", item.embed_code)
                    asset.AddReplace("duration", item.duration)
                    asset.AddReplace("name", item.name)
                    asset.AddReplace("posterURL", item.preview_image_url)
                    asset.AddReplace("stream", findBestStreamURLForRemoteAsset(item.stream_urls))
                    asset.AddReplace("is_live", item.is_live_stream)
                    remote.push(asset)
                end if
            end if
        end if
    end For
    assets.push(backlot)
    assets.push(remote)
    return assets

End Function

Function findBestStreamURLForRemoteAsset(streamUrls as Object)
    flashUrl = streamUrls.flash
    For each streamType in streamUrls
        streamURL = streamUrls[streamType]
        if streamURL <> invalid and streamURL.Instr(".m3u8") <> -1
            return streamURL
        end if
    end for
    return flashUrl
End Function

Function addParamToQuery(query as String, param as String, value as String) as void
    if(query.Instr(0,"?") = -1)
        query.appendString("?",1)
    else
        query.appendString("&",1)
    end if
    
    query.appendString(param, param.len())
    query.appendString("=",1)
    query.appendString(value, value.len())
End Function


Function generateSignature(api_key as String, secret as String, route as String) as String
    expiringTime = "1999991855"

    queryText = box("")
    queryText.appendString(SECRET,SECRET.len()) 'append the secret key
    queryText.appendString("GET", 3)
    queryText.appendString(route, route.Len()) 'then the route
    queryText.appendString("api_key=", 8) 'then the api key
    queryText.appendString(API_KEY,API_KEY.len())
    queryText.appendString("expires=", 8) 'expiring time
    queryText.appendString(expiringTime,expiringTime.len())

    ba=CreateObject("roByteArray")
    ba.FromAsciiString(queryText)

    rokuDigest = CreateObject("roEVPDigest")
    rokuDigest.setup("sha256")

    signature = rokuDigest.process(ba)
    byteArraySignature=CreateObject("roByteArray")
    byteArraySignature.fromhexstring(signature)

    signatureBase64 = byteArraySignature.ToBase64String()
    urlEncoder = CreateObject("roUrlTransfer")
    signatureEncoded = urlEncoder.Escape(signatureBase64.left(43))

    return signatureEncoded
End Function

'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "15"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/Logo_Overhang_SD43.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "40"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/ooyala_logo_footer_hd.png"
    
    app.SetTheme(theme)

End Sub

