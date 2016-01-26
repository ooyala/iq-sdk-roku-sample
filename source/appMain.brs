
Sub Main()

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'Create an instance of Ooyala IQ and initialize it
    m.iq = IQ()
    m.iq.init()
    
    'Create an instance of roPosterScreen to display video playback method selection. 
    screenFacade = CreateObject("roPosterScreen")
    screenFacade.show()
    
    itemVenter = { ContentType:"episode"
               SDPosterUrl:"file://pkg:/images/CraigVenter-2008.jpg"
               HDPosterUrl:"file://pkg:/images/kitcat.png"
               IsHD:False
               HDBranded:False
               ShortDescriptionLine1:"An interesting video"
               ShortDescriptionLine2:""
               Description:"A very very interesting video"
               Rating:"NR"
               StarRating:"80"
               Length:1972
               Categories:["Technology","Talk"]
               Title:"A great video"
               }

    m.itemVenter = itemVenter
    
    'Create videoclip and contentlist object to store video content for roVideoScreen and roVideoPlayer
    m.videoclip = CreateObject("roAssociativeArray")
    m.contentList = []
    
    'Display the poster screen
    showSpringboardScreen(itemVenter) 
   
    'exit the app gently so that the screen doesn't flash to black
    screenFacade.showMessage("")
    sleep(25)
End Sub

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


'*************************************************************
'** showSpringboardScreen()
'*************************************************************

Function showSpringboardScreen(item as object) As Boolean
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    print "showSpringboardScreen"
    
    screen.SetMessagePort(port)
    'To avoid flashing the screen while adding buttons to layout, temporarly stop display update.
    screen.AllowUpdates(false)
    
    'Validate the provided item and assign it as SpringboardScreen
    if item <> invalid and type(item) = "roAssociativeArray"
        screen.SetContent(item)
    endif
    
    'Set up the poster screen layout
    screen.SetDescriptionStyle("generic") 
    screen.ClearButtons()
    screen.AddButton(1,"Play with VideoScreen")
    screen.AddButton(2,"Play with VideoPlayer")
    screen.AddButton(3,"Go Back")
    screen.SetStaticRatingEnabled(false)
    'Refresh the display 
    screen.AllowUpdates(true)
    screen.Show()

    
    'Wait for user interaction
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSpringboardScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    
                    'User selects "Play with VideoScreen"
                    if msg.GetIndex() = 1
                         displayScreen()   
                    
                    'User selects "Play with VideoPlayer" 
                    else if msg.GetIndex() = 2
                         display = displayVideo()
                         display.paint()
                         display.eventloop()
                     
                     'User selects "Go Back"    
                    else if msg.GetIndex() = 3
                         return true
                    endif
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        else 
            print "wrong type.... type=";msg.GetType(); " msg: "; msg.GetMessage()
        endif
    end while
    
    return true
End Function


'*************************************************************
'** Display video using roVideoScreen 
'*************************************************************
Function displayScreen()
print "Displaying video: "
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    'Load video content
    LoadVideo()
    
    'Assign videocontent to video screen Object
    video.SetContent(m.videoclip)
    'Provide content metadata to IQ plugin
    m.iq.setContentMetadata({duration : 52, pcode: "A0a2wxOmS0RHjawbnO1iOx1S9uc7"})
    video.SetPositionNotificationPeriod(1)'DO NOT FORGET TO ADD THIS FOR GOOD PLAYHEAD UPDATE
    
    'Start video screen playback
    video.show()
    'Notify IQ about playback request
    m.iq.notifyPlayRequested(false)


    lastSavedPos   = 0
    statusInterval = 10 'position must change by more than this number of seconds before saving

    while true
        msg = wait(1000, video.GetMessagePort())
        m.iq.handleEvent(msg)
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
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
end Function

'*************************************************************
'** Display video using roVideoPlayer
'*************************************************************
Function displayVideo() as Object
    print "Displaying video: "
     
     'Initialize required objects for video player  
     this = {
        port:      CreateObject("roMessagePort")
        progress:  0 'buffering progress
        position:  0 'playback position (in seconds)
        paused:    false 'is the video currently paused?
        playlistSize: 0
        canvas:    CreateObject("roImageCanvas") 'user interface
        player:    CreateObject("roVideoPlayer")
        videoclip: m.videoclip
        contentlist: m.contentlist
        load:      LoadVideo
        paint:     PaintFullscreenCanvas
        eventloop: EventLoop
        iq:        m.iq
        itemVenter: m.itemVenter
    }
   
    this.targetRect = this.canvas.GetCanvasRect()
    'Load video content
    this.load()
    'Assign video content list to video player. In this integration there is only one video in the contentlist. 
    this.player.SetContentList(m.contentList)  
    'Setup image canvas:
    this.canvas.SetMessagePort(this.port)
    this.canvas.SetLayer(0, { Color: "#000000" })
    this.canvas.Show()

    this.player.SetMessagePort(this.port)
    this.player.SetLoop(true)
    this.player.SetPositionNotificationPeriod(1)
    this.player.SetDestinationRect(this.targetRect)
    
    
   'Provide content metadata to IQ plugin. This should be done dnamically rather than using hardcoded duration value.
    m.iq.setContentMetadata({duration : 52, pcode: "A0a2wxOmS0RHjawbnO1iOx1S9uc7"})
    
    this.player.Play() 
    'Notify IQ about playback request
    m.iq.notifyPlayRequested(false)
        

    return this
        
End Function

'******************************************************************************
'** EventLoop listening to user interaction while roVideoPlayer is playing.
'******************************************************************************
Sub EventLoop()
    while true
        msg = wait(1000, m.port)
        'Inform iq about the event.    
        m.iq.handleEvent(msg)
        if msg <> invalid
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                print "Raw progress: " + stri(msg.GetIndex())
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                end if

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()

            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                
                if index = 0 '<BACK>
                    m.player.Stop()
                    showSpringboardScreen(m.itemVenter)
                    
                else if index = 8 '<REV>
                    if m.position > 20
                    m.position = m.position - 20
                    m.player.Seek(m.position * 1000)                
                    else 
                        m.player.Seek(0)
                    end if    
                else if index = 9 '<REV>
                    m.position = m.position + 20
                    m.player.Seek(m.position * 1000)
              
                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
                end if

            else if msg.isPaused()
                m.paused = true
                m.paint()

            else if msg.isResumed()
                m.paused = false
                m.paint()

            end if
         end if
    end while
End Sub

'Update roImageCanvas
Sub PaintFullscreenCanvas()
    'Clear previous contents
    m.canvas.ClearLayer(0)
    m.canvas.ClearLayer(1)
    m.canvas.ClearLayer(2)    
    m.canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source" })
  
End Sub

'******************************************************************************
'**Load video content and assign it to videoclip and contentList. roVideoScreen 
'**uses videoclip object and roVideoPlayer requires contentList.
'******************************************************************************

Function LoadVideo() as void
    
    bitrates  = [0]    
    urls = ["http://pulse-demo.cdn.videoplaza.tv/resources/media/sintel_trailer_854x480.mp4"]
    qualities = ["HD"]
    StreamFormat = "mp4"
    title = "An amazing video"
    srt = "http://dotsub.com/media/f65605d0-c4f6-4f13-a685-c6b96fba03d0/c/eng/srt"
    
    'Assign video content to videoclip 
    m.videoclip.StreamBitrates = bitrates
    m.videoclip.StreamUrls = urls
    m.videoclip.StreamQualities = qualities
    m.videoclip.StreamFormat = streamformat
    m.videoclip.Title = title
    print "srt = ";srt
    if srt <> invalid and srt <> "" then
        m.videoclip.SubtitleUrl = srt
    end if
    
    'Push video content into contentList
    m.playlistSize = 1
    
    m.contentList.push(m.videoclip)  

End Function
