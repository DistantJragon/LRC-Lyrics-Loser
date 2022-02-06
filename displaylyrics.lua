function Initialize()
	TitleMeasure = SKIN:GetMeasure('MeasureTitle')
	oldTitle = TitleMeasure:GetStringValue()
	ArtistMeasure = SKIN:GetMeasure('MeasureArtist')
	oldArtist = ArtistMeasure:GetStringValue()
	AlbumMeasure =  SKIN:GetMeasure('MeasureAlbum')
	album = AlbumMeasure:GetStringValue()
	LocalLRCLyricsMeasure = SKIN:GetMeasure('MeasureLocalLRCLyrics')
	localLRCLyrics = LocalLRCLyricsMeasure:GetStringValue()
	LocalTXTLyricsMeasure = SKIN:GetMeasure('MeasureLocalTXTLyrics')
	localTXTLyrics = LocalTXTLyricsMeasure:GetStringValue()
	GeniusLyricsMeasure = SKIN:GetMeasure('MeasureMatch')
	geniusLyrics = GeniusLyricsMeasure:GetStringValue()
	PositionMeasure = SKIN:GetMeasure('MeasurePosition')
	position = PositionMeasure:GetValue() * 1000
	StateMeasure = SKIN:GetMeasure('MeasureState')
	state = StateMeasure:GetValue()
	DurationMeasure = SKIN:GetMeasure('MeasureDuration')
	duration = DurationMeasure:GetValue() * 1000
	skinPath = SKIN:GetVariable('CURRENTPATH')
	lyricsWithoutTags = ""
	displayLyricsOrganized = false
	makerLyricsOrganized = false
	skinUpdate = 100         -- If changed, change in .ini file aswell
	currentLine = 0
	displayTagList = {}
	displayLyricList = {}
	makerLyricList = {}
	makerTagList = {}
	makerMilList = {}
	makerLineList = {}
	makerLyrics = "NILNotfoundNIL"
end
	
function Update()
	-- update variables
	state = StateMeasure:GetValue()
	webNowPlayingPosition = PositionMeasure:GetValue() * 1000
	makerMode = SELF:GetOption('makerMode', 'false')
	clickedDone = SELF:GetOption('clickedDone', 'false')
	clickedPrevLine = SELF:GetOption('clickedPrevLine', 'false')
	clickedNextLine = SELF:GetOption('clickedNextLine', 'false')
	clickedgenius = SELF:GetOption('clickedNextLine', 'false')
	clickedDownload = SELF:GetOption('clickedDownload', 'false')
	
	-- if webNowPlaying position updated, update position to prevent desync (rainmeter update isn't exact)
	if webNowPlayingPosition ~= oldWebNowPlayingPosition then position = webNowPlayingPosition end 
	oldWebNowPlayingPosition = webNowPlayingPosition
	
	if clickedDownload == "true" then
		if geniusLyrics ~= "NILNotfoundNIL" then
			newTXTLyricsFile = io.open(skinPath .. '\\Lyrics\\' .. newArtist .. ' - ' .. newTitle .. '.txt', 'w')
			if not newTXTLyricsFile then 
				print('Can\'t create file: Lyrics\\' .. newArtist .. ' - ' .. newTitle .. '.txt')
			else
				newTXTLyricsFile:write(geniusLyrics)
				newTXTLyricsFile:close()
				DownloadedTxtWritten = true
				SKIN:Bang("!Refresh")
			end
		end
	end
	
	if localLRCLyrics == "NILNotfoundNIL" then localLRCLyrics = LocalLRCLyricsMeasure:GetStringValue() end
	if localTXTLyrics == "NILNotfoundNIL" then localTXTLyrics = LocalTXTLyricsMeasure:GetStringValue() end
	if geniusLyrics == "NILNotfoundNIL" then geniusLyrics = GeniusLyricsMeasure:GetStringValue() end -- find lyrics
	-- state: 0 = stopped, 1 = playing, 2 = paused
	if state == 1 then
		position = position + skinUpdate
		SKIN:Bang('!SetOption', 'MeterPlay', 'ImageCrop', '41,0,41,41,1') -- sets button in maker mode to pause button
	elseif state == 2 or state == 0 then
		SKIN:Bang('!SetOption', 'MeterPlay', 'ImageCrop', '0,0,41,41,1')  -- sets button in maker mode to play button
	end
	
	if duration == 0 then duration = DurationMeasure:GetValue() * 1000 end -- don't know why this is here but it's not hurting
	
	if makerMode == "false" then -- if in display mode
		if localLRCLyrics ~= "NILNotfoundNIL" and displayLyricsOrganized == false then -- if found, organize
			DisplayLRCLyricOrganize(localLRCLyrics)
			displayLyricsOrganized = true
		end
		
		newTitle = TitleMeasure:GetStringValue()
		newArtist = ArtistMeasure:GetStringValue()
		if newTitle ~= oldTitle or newArtist ~= oldArtist then
			SKIN:Bang("!Refresh")
		end
		if displayLyricsOrganized then
			for displayLineNumberCheck = 1, #displayTagList do
				if position >= displayTagList[displayLineNumberCheck] then
					currentLine = displayLineNumberCheck
				else
					break
				end
			end
			if currentLine >= 0 and currentLine <= 2 and displayLyricList[1] ~= nil then
				SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', displayLyricList[1] .. "\r\n" .. displayLyricList[2] .. "\r\n" .. displayLyricList[3])
			elseif currentLine <= #displayLyricList and currentLine >= #displayLyricList - 2 then
				SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', displayLyricList[#displayLyricList - 2] .. "\r\n" .. displayLyricList[#displayLyricList - 1] .. "\r\n" .. displayLyricList[#displayLyricList])
			elseif currentLine > 2 and displayLyricList[1] ~= nil then
				SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', displayLyricList[currentLine - 1] .. "\r\n" .. displayLyricList[currentLine] .. "\r\n" .. displayLyricList[currentLine + 1])
			end
		else
			SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', "\r\n" .. "Not found" .. "\r\n")
		end
		
	elseif makerMode == "true" then
		local makerTagListTemporaryMinHolder = math.floor(position / 60000)
		local makerTagListTemporarySecHolder = math.floor(position / 1000) - (makerTagListTemporaryMinHolder * 60)
		local makerTagListTemporaryCentHolder = math.floor(position / 10) - (makerTagListTemporarySecHolder * 100) - (makerTagListTemporaryMinHolder * 6000)
		-- Cent meaning centisecond in [xx:xx.xx] (the xx after the .)
		if makerTagListTemporaryMinHolder < 10 then makerTagListTemporaryMinHolder = "0" .. makerTagListTemporaryMinHolder end
		if makerTagListTemporarySecHolder < 10 then makerTagListTemporarySecHolder = "0" .. makerTagListTemporarySecHolder end
		if makerTagListTemporaryCentHolder < 10 then makerTagListTemporaryCentHolder = "0" .. makerTagListTemporaryCentHolder end
		
		if makerLyrics == "NILNotfoundNIL" then
			if localLRCLyrics ~= "NILNotfoundNIL" then
				makerLyrics = localLRCLyrics
				MakerLRCLyricOrganize(makerLyrics)
				makerLyricsOrganized = true
				print("LRC")
			elseif localTXTLyrics ~= "NILNotfoundNIL" then
				makerLyrics = localTXTLyrics
				MakerTXTLyricOrganize(makerLyrics)
				makerLyricsOrganized = true
				print("TXT")
			elseif geniusLyrics ~= "NILNotfoundNIL" then
				makerLyrics = geniusLyrics
				MakerGeniusLyricOrganize(makerLyrics)
				makerLyricsOrganized = true
				print("gen")
			end
		end
		
		if clickedPrevLine == "true" then
			currentLine = currentLine - 1
			if currentLine < 0 then currentLine = 0 end
			if currentLine == 0 then 
				SKIN:Bang('!CommandMeasure', 'MeasureArtist', 'SetPosition 0') 
			else 
				SKIN:Bang('!CommandMeasure', 'MeasureArtist', 'SetPosition ' .. tostring(makerMilList[currentLine] * 100 / duration)) 
			end
		end
		if clickedNextLine == "true" then
			if currentLine < #makerLineList then currentLine = currentLine + 1 end
			makerTagList[currentLine] = "[" .. makerTagListTemporaryMinHolder .. ":" .. makerTagListTemporarySecHolder .. "." .. makerTagListTemporaryCentHolder .. "]"
			makerMilList[currentLine] = position
			makerLineList[currentLine] = makerTagList[currentLine] .. makerLyricList[currentLine]
		end
		
		if makerLyricsOrganized then
			if currentLine >= 0 and currentLine <= 2 and makerLineList[1] ~= nil then
				SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', makerLineList[1] .. "\r\n" .. makerLineList[2] .. "\r\n" .. makerLineList[3])
			elseif currentLine <= #makerLineList and currentLine >= #makerLineList - 1 then
				SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', makerLineList[#makerLineList - 2] .. "\r\n" .. makerLineList[#makerLineList - 1] .. "\r\n" .. makerLineList[#makerLineList])
			elseif currentLine > 2 and currentLine < #makerLineList - 1 then
				SKIN:Bang('!SetOption', 'MeterLyrics', 'Text', makerLineList[currentLine - 1] .. "\r\n" .. makerLineList[currentLine] .. "\r\n" .. makerLineList[currentLine + 1])
			end
		end
		
		if #makerLineList == #makerTagList then
			SKIN:Bang('!SetOption', 'MeterDone', 'ImageCrop', '164,0,41,41,1') -- Set done button to check
		else
			SKIN:Bang('!SetOption', 'MeterDone', 'ImageCrop', '287,0,41,41,1') -- Set done button to X
		end
		if clickedDone == "true" then
			if #makerLineList == #makerTagList then
				durationString = DurationMeasure:GetStringValue()
				yourName = SKIN:GetVariable('yourName')
				watermark = SKIN:GetVariable('watermarkTopOfLyricsFile')
				newLRCLyricsFileTempOutput = "[ar:"..oldArtist.."]\n[al:"..album.."]\n[ti:"..oldTitle.."]\n[length: "..durationString.."]\n"
				if yourName ~= "Anonymous" then newLRCLyricsFileTempOutput = newLRCLyricsFileTempOutput.."[by:"..yourName.."]\n" end
				if watermark == "true" then newLRCLyricsFileTempOutput = newLRCLyricsFileTempOutput.."[re:LRC Lryics, Loser Rainmeter Skin]\n" end
				newLRCLyricsFileTempOutput = newLRCLyricsFileTempOutput.."\n"
				for makerLineNumberCheck = 1, #makerLineList do
					newLRCLyricsFileTempOutput = newLRCLyricsFileTempOutput .. makerLineList[makerLineNumberCheck]
					if makerLineNumberCheck ~= #makerLineList then newLRCLyricsFileTempOutput = newLRCLyricsFileTempOutput.."\n" end
				end
				newLRCLyricsFile = io.open(skinPath .. '\\Lyrics\\' .. oldArtist .. ' - ' .. oldTitle .. '.lrc', 'w')
				if not newLRCLyricsFile then 
					print('Can\'t create file: Lyrics\\' .. oldArtist .. ' - ' .. oldTitle .. '.lrc')
				else
					newLRCLyricsFile:write(newLRCLyricsFileTempOutput)
					newLRCLyricsFile:close()
				end  
			end
			SKIN:Bang("!Refresh")
		end
	end
	SKIN:Bang('!SetOption', 'MeasureLyricsLines', 'clickedGenius', 'false')
	SKIN:Bang('!SetOption', 'MeasureLyricsLines', 'clickedNextLine', 'false')
	SKIN:Bang('!SetOption', 'MeasureLyricsLines', 'clickedPrevLine', 'false')
	SKIN:Bang('!SetOption', 'MeasureLyricsLines', 'clickedDone', 'false')
	if DownloadedTxtWritten then
		SKIN:Bang('!SetOption', 'MeasureLyricsLines', 'clickedDownload', 'false')
		DownloadedTxtWritten = false
	end
end

function DisplayLRCLyricOrganize(LyricsString)
	displayTagList = {}
	displayLyricList = {}
	local str = LyricsString
	local startFound = false
	local lineNumber = 0
	local tagToMils = 0
	for line in str:gmatch("[^\r\n]+") do
		if string.match(line, "^%[%d%d:%d%d%.%d%d%]") and startFound == false then
			startFound = true
		end
		if startFound then
			if string.match(line, "^%[%d%d:%d%d%.%d%d%]") then
				lineNumber = lineNumber + 1
				tagToMils = (string.sub(line, 2, 3) * 60000) + (string.sub(line, 5, 6) * 1000) + (string.sub(line, 8, 9) * 10)
				displayTagList[lineNumber] = tagToMils
				displayLyricList[lineNumber] = string.sub(line, 11)
			end
		end
	end
end

function MakerLRCLyricOrganize(LyricsString)
	makerTagList = {}
	makerLyricList = {}
	local str = LyricsString
	local lineNumber = 0
	local startFound = false
	for line in str:gmatch("[^\r\n]+") do
		if string.match(line, "^%[%d%d:%d%d%.%d%d%]") and startFound == false then
			startFound = true
		end
		if startFound then
			if string.match(line, "^%[%d%d:%d%d%.%d%d%]") then
				lineNumber = lineNumber + 1
				makerLyricList[lineNumber] = string.sub(line, 11)
				makerLineList[lineNumber] = string.sub(line, 11)
			end
		end
	end
end

function MakerTXTLyricOrganize(LyricsString)
	makerTagList = {}
	makerLyricList = {}
	local str = LyricsString
	local lineNumber = 0
	for line in io.lines(skinPath..'\\Lyrics\\'.. oldArtist..' - '..oldTitle..'.txt') do
		lineNumber = lineNumber + 1
		makerLyricList[lineNumber] = line
		makerLineList[lineNumber] = line
	end
end

function MakerGeniusLyricOrganize(LyricsString)
	makerTagList = {}
	makerLyricList = {}
	local str = LyricsString
	local lineNumber = 0
	for line in str:gmatch("[^\r\n]+") do
		lineNumber = lineNumber + 1
		makerLyricList[lineNumber] = line
		makerLineList[lineNumber] = line
	end
end