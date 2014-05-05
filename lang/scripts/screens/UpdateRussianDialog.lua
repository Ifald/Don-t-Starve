local Screen = require "widgets/screen"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"



local UpdateRussianDialog = Class(Screen, function(self,postfn,calledfromoptions)
	Screen._ctor(self, "UpdateRussianDialog")
	self.postfunction=postfn
	
	self:DoInit(calledfromoptions)
end)

--Переводит все обновлённые строки из chapterslist в STRINGS
local function DoTranslateSTRINGStoRussian()
	for _,chapter in ipairs(chapterslist) do if chapter.data then
		for _,record in ipairs(chapter.data) do if record.isupdated then
			local tags=string.split(record.tag,".")
			local str=STRINGS
			for i=2,#tags-1 do
				if str[tags[i]] then
					str=str[tags[i]]
				else
					str=nil
					break
				end
			end
			if str and str[tags[#tags]] then
				local tmp=record.rus:gsub("\\\"","\"")
				local tmp=tmp:gsub("\\n","\n")
				local tmp=tmp:gsub("\\r","")
				str[tags[#tags]]=tmp
				record.isupdated=false
			end
		end end
	end end
end


local function BuildNewPO()
	local poheader="# "..RussificationURL.."\n".."# Версия "..RussificationVersion..[[


msgid ""
msgstr ""
"Project-Id-Version: Перевод игры Don't Starve\n"
"Last-Translator: Some1 <Some1@email.ua>\n"
"POT Version: 2.0\n"

]]
		
	local f = assert(io.open(RussificationStorePath..russianpofilename,"w"))
	f:write(poheader.."\n\n")
	for _,chapter in ipairs(chapterslist) do
		if chapter.data then
			f:write("\n\n# ------------------------------------------------------------------------------ Глава "..chapter.name.."\n\n")
			for _,record in ipairs(chapter.data) do
				local adder=""
				if record.disabled or record.rus==record.eng then
					adder="~"
				end
				f:write(adder.."#. "..record.tag.."\n")
				f:write(adder.."msgctxt \""..record.tag.."\"\n")
				f:write(adder.."msgid \""..record.eng.."\"\n")
				f:write(adder.."msgstr \""..record.rus.."\"\n\n")
			end
		end
	end

	if shouldbecapped then --Таблица слов, начинающихся с заглавных букв
		f:write("\n\n\n# ------------------------------------------------------------------------------ Должны начинаться с заглавной буквы\n\n")
		for v,i in pairs(shouldbecapped) do
			f:write("#"..v:upper().."\n")
		end
		f:write("\n\n")
	end

	for action,actiontable in pairs(actionstosave) do --Запишем таблицы действий

		f:write("\n\n\n# ------------------------------------------------------------------------------ Действие "..string.lower(action).."\n\n")
		for _,record in pairs(actiontable) do
			local s1
			if action=="DEFAULTACTION" then
				s1="#Изучить "
			elseif action=="WALKTO" then
				s1="#Идти к "
			else
				s1="#"..(STRINGS.ACTIONS[action] or "").." "
			end
			s1=s1..record.trans
			local len=#s1
			while len<56 do
				s1=s1.."\t"
				len=len+8
			end
			s1=s1..tostring(record.orig)--STRINGS.NAMES[item]
			len=#tostring(record.orig)--STRINGS.NAMES[item]
			while len<48 do
				s1=s1.."\t"
				len=len+8
			end
			s1=s1..record.pth.."\n"
			f:write(s1)
		end
	end
	f:write("\n\n\n# ------------------------------------------------------------------------------ perishable\n\n")
	for _,line in ipairs(perishableforsave) do
		f:write(line.."\n")
	end
	f:close()
end


function UpdateRussianDialog:DoInit(calledfromoptions)

	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0,0,0,.75)	
    
    self.root = self:AddChild(Widget("ROOT"))--self.root = self.scaleroot:AddChild(Widget("root"))
    self.root:SetScale(.9)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.bg = self.root:AddChild(Image("images/fepanels.xml", "panel_saveslots.tex"))

	
	--title	
    self.title = self.root:AddChild(Text(TITLEFONT, 50))
    self.title:SetPosition(0, 222, 0)
    self.title:SetString("Обновление русификации")


	--text

	self.text={}

	chapterslist=ChaptersListInit()
	
	for i=1,#chapterslist do
		table.insert(self.text,self.root:AddChild(Text(BODYTEXTFONT, 23)))
		self.text[i]:SetPosition(75, 205-i*22, 0)
		self.text[i]:SetVAlign(ANCHOR_TOP)
		self.text[i]:SetHAlign(ANCHOR_LEFT)
		self.text[i]:SetString(chapterslist[i].text)
		self.text[i]:EnableWordWrap(true)
		self.text[i]:SetRegionSize(500, 30)
		if i>1 then
			self.text[i]:SetColour(.5,.5,.5,1)
		else
			self.text[i]:SetColour(1,.5,.5,1)
		end
	end
  
	self.wasclosed=false

	self.cb = function()
		self.wasclosed=true
		TheFrontEnd:PopScreen()
	end

	self.CloseButton = self.root:AddChild(ImageButton())
	self.CloseButton:SetPosition(2, -250) 
	self.CloseButton:SetScale(0.8) 
	self.CloseButton:SetText("Отменить")
	self.CloseButton:SetOnClick(self.cb)

	self.default_focus = self.CloseButton

	self.Info = self.root:AddChild(ImageButton("images/ui.xml", "button_long.tex", "button_long_over.tex", "button_long_disabled.tex"))
	self.Info:SetPosition(-132, -241)
	self.Info:SetText("О программе")
	self.Info:SetScale(0.6)
	self.Info:SetOnClick( function()
		local PopupDialogScreen = require "screens/popupdialog"
	        TheFrontEnd:PushScreen(PopupDialogScreen("Русификация игры "..RussificationVersion, russianmoddescription,
			{{text="Посетить сайт", cb = function() VisitURL(RussificationURL) end},
			 {text=STRINGS.UI.CONTROLSSCREEN.CLOSE, cb = function() TheFrontEnd:PopScreen() end}}))
	end )

	self.ToSettings = self.root:AddChild(ImageButton("images/ui.xml", "button_long.tex", "button_long_over.tex", "button_long_disabled.tex"))
	if calledfromoptions then
		self.ToSettings:Disable()
	end
	self.ToSettings:SetPosition(132, -241)
	self.ToSettings:SetText("Настройки")
	self.ToSettings:SetScale(0.6)
	self.ToSettings:SetOnClick( function()
		local LanguageOptions=require "screens/LanguageOptions"
		TheFrontEnd:PushScreen(LanguageOptions())
	end )

	--Управление с клавиатуры
	self.Info:SetFocusChangeDir(MOVE_RIGHT, self.CloseButton)
	self.CloseButton:SetFocusChangeDir(MOVE_LEFT, self.Info)
	self.CloseButton:SetFocusChangeDir(MOVE_RIGHT, self.ToSettings)
	self.ToSettings:SetFocusChangeDir(MOVE_LEFT, self.CloseButton)


	local step=0
	local downloadlog=""



	--Загружаем главы из по файла
	local CurrentChapter=nil
	local f=io.open(RussificationStorePath..russianpofilename,"r")
	if f then for line in f:lines() do
		line=escapeR(line)
		if CurrentChapter then
			if string.sub(line,1,10)=="#. STRINGS" then --добавляем имеющиеся записи
				chapterslist[CurrentChapter].data=chapterslist[CurrentChapter].data or {}
--				line=line:gsub("\\\"","<QUOTES>") --экранируем кавычки в строках текста
				local tmp=string.sub(line,4)
				if tmp then
--					tmp=tmp:gsub("<QUOTES>","\\\"")
					tmp=escapeR(tmp)
					table.insert(chapterslist[CurrentChapter].data,{tag=tmp})
				end

			elseif  string.sub(line,1,11)=="~#. STRINGS" then --неактивные но присутствующие записи
				chapterslist[CurrentChapter].data=chapterslist[CurrentChapter].data or {}
--				line=line:gsub("\\\"","<QUOTES>") --экранируем кавычки в строках текста
				local tmp=string.sub(line,5)
				if tmp then
--					tmp=tmp:gsub("<QUOTES>","\\\"")
					tmp=escapeR(tmp)
					table.insert(chapterslist[CurrentChapter].data,{tag=tmp,disabled=true})
				end
			end
			if string.sub(line,1,6)=="msgstr" or string.sub(line,1,7)=="~msgstr" then --Это русский текст для самой последней найденой в текущей главе записи
				local tmp=string.match(line,"\"(.*)\"")
				if tmp and chapterslist[CurrentChapter].data then
					chapterslist[CurrentChapter].data[#chapterslist[CurrentChapter].data].rus=tmp
				end
			end
			if string.sub(line,1,5)=="msgid" or string.sub(line,1,6)=="~msgid" then --Это английский текст для самой последней найденой в текущей главе записи
				local tmp=string.match(line,"\"(.*)\"")
				if tmp and chapterslist[CurrentChapter].data then
					chapterslist[CurrentChapter].data[#chapterslist[CurrentChapter].data].eng=tmp
				end
			end
		end
		if string.sub(line,1,7)=="# -----" and string.find(line,"Глава") then --начинается новая глава
			local tmp=string.match(line,"Глава (.+)$")
			if tmp and tmp~="" then
				CurrentChapter=nil
				for i,v in ipairs(chapterslist) do
					if v.name==tmp then
						CurrentChapter=i
						break
					end
				end
			end
		end

	end f:close() end
	local _utf8=require "1251"
	local function convertfromutf8(data, donotmaskquotes)
		local translations={}
		local isutf8=true
		local isfirst=true
		local data1=string.split(data,"\r\n")
		for _,line in ipairs(data1) do
			if isutf8 then
				local line2=""
				for uchar in string.gfind(line, "([%z\1-\127\194-\244][\128-\191]*)") do
					if isfirst and uchar~="\239\187\191" then
						isutf8=false
						line2=line
						break
					end
					isfirst=false
				
		        		if #uchar==1 then
						line2=line2..uchar
					elseif #uchar==2 then
						local res=(uchar:byte(1)-0xC0)*0x40+uchar:byte(2)-0x80
						if _utf8[res] then line2=line2..string.char(_utf8[res]) end
--					else poheader=poheader.."*"--"["..uchar.." - "..line.."]"
					end
				end
				line=line2
		        end
			if line~="" and line~="Внимание! Этот перевод, возможно, ещё не готов." then
				if not donotmaskquotes then
					line=line:gsub("([^\\])\"","%1\\\"") --экранируем кавычки в строках текста
				end
				table.insert(translations,line) --Добавляем строку
			elseif line=="Внимание! Этот перевод, возможно, ещё не готов." then
				break
			end
		end		
		return translations
	end

	--подстановка правильного окончания
	local function changestext(num) 
		local str="й"
		while num>100 do num=num/10 end
		if num>20 then while num>10 do num=num%10 end end
		if num==1 then str="е" elseif num==2 or num==3 or num==4 then str="я" end
		return " изменени"..str
	end
	--сравнение двух таблиц, используется для поиска изменений в таблицах склонений и т.п.
	local function deepcompare(t1,t2,ignore_mt)
		local ty1 = type(t1)
		local ty2 = type(t2)
		if ty1 ~= ty2 then return false end
		-- non-table types can be directly compared
		if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
		-- as well as tables which have the metamethod __eq
		local mt = getmetatable(t1)
		if not ignore_mt and mt and mt.__eq then return t1 == t2 end
		for k1,v1 in pairs(t1) do
			local v2 = t2[k1]
			if v2 == nil or not deepcompare(v1,v2) then return false end
		end
		for k2,v2 in pairs(t2) do
			local v1 = t1[k2]
			if v1 == nil or not deepcompare(v1,v2) then return false end
		end
		return true
	end

	local FoundSomeDifference=false
	--Функция, с помощью которой происходит вся загрузка из нотабеноида
	local function DoDownload(...)
		if self.wasclosed then
			return nil
		end
		local url=RussificationURL
		local params="/download?format=t&enc=UTF-8"
		if ... and step==#chapterslist+1 then --Загружаем дополнительную скрытую главу с склонениями и т.п.
			local tbl={...}
			if tbl and #tbl==3 and tbl[3]==200 then --получили ответ от сервера и он положителен
				local data=convertfromutf8(tbl[1],true)
				--делаем бэкапы для последующего сохранения
				local oldshouldbecapped=shouldbecapped
				local oldrussiannames=russiannames
				local oldperishablerus=perishablerus

				loadcappednames(data) --Загружаем имена, которые должны оставаться заглавными. Должно быть перед применением перевода в STRINGS
				LoadFixedAdjectives(data) --загружаем исправленные качества продуктов
				loadfixednames(false,data) --загружаем исключения склонений

				if not deepcompare(oldshouldbecapped,shouldbecapped) then FoundSomeDifference=true end
				if not deepcompare(oldrussiannames,russiannames) then FoundSomeDifference=true end
				if not deepcompare(oldperishablerus,perishablerus) then FoundSomeDifference=true end
			end
		elseif ... then --пустые они будут если сервер не вернёт ответа или в самый первый раз
			downloadlog=downloadlog.."\nГлава "..chapterslist[step].name.." ("..chapterslist[step].text..")\n"
			self.text[step]:SetColour(1,1,1,1)

			if step<#chapterslist then
				self.text[step+1]:SetColour(1,.5,.5,1)
			end

			local tbl={...}
			if tbl and #tbl==3 and tbl[3]==200 and step>0 and step<=#chapterslist then --получили ответ от сервера и он положителен
				local translations=convertfromutf8(tbl[1])
				if translations then --удалось преобразовать в строки ansi
--					downloadlog=downloadlog.."Записей: "..#translations.."\n"
					if #translations~=#chapterslist[step].data then --разное количество записей
						self.text[step]:SetString(chapterslist[step].text.." — не совпадает кол-во записей")
						--[[if false then --Отладочный код создаёт логи с главами, в которых не совпадает
							local f=io.open(russianmodpath.."error_"..chapterslist[step].name..".txt","w")
							for i=1,#translations do
								f:write(translations[i].."\n")
								if chapterslist[step].data[i] and translations[i]==chapterslist[step].data[i].rus then f:write("OK") else f:write("ОШИБКА") end
								f:write("\n\n")
							end
							f:close()
						end --]]
					else --одинаковое количество записей
						local DifferenceCounter=0
						for i=1,#translations do --ищем количество несовпадений в таблицах
							translations[i]=string.gsub(translations[i],"\\(%d%d?%d?)",function(val)
								return string.char(tonumber(val))
							end)
							if translations[i]~=chapterslist[step].data[i].rus then
								downloadlog=downloadlog.."\t"..chapterslist[step].data[i].tag.."\n\t\tpo: "..chapterslist[step].data[i].rus.."\n\t\tнота: "..translations[i].."\n"
								DifferenceCounter=DifferenceCounter+1
								chapterslist[step].data[i].rus=translations[i]
								chapterslist[step].data[i].disabled=translations[i]==chapterslist[step].data[i].eng
								chapterslist[step].data[i].isupdated=true
							end
						end
						if DifferenceCounter~=0 then --есть несовпадения
							self.text[step]:SetString(chapterslist[step].text.." — "..DifferenceCounter..changestext(DifferenceCounter))
							FoundSomeDifference=true
						else -- всё совпадает
--							self.text[step]:SetString(chapterslist[step].text.." — без изменений")
							downloadlog=downloadlog.."Нет изменений\n"

						end
					end
				else --неудалось преобразовать в строки ansi
					self.text[step]:SetString(chapterslist[step].text.." — Ошибка")
				end
			else  --сервер вернул ошибку или не вернул данных вообще.
				self.text[step]:SetString(chapterslist[step].text.." — Ошибка")
				downloadlog=downloadlog.."Ошибка сервера\n"
			end 
		end
		step=step+1
		if step<=#chapterslist then
			TheSim:QueryServer( url..chapterslist[step].id..params, DoDownload, "GET" )
		elseif step==#chapterslist+1 then --Загружаем дополнительную скрытую главу с склонениями и т.п.
			TheSim:QueryServer( url.."192218"..params, DoDownload, "GET" )
		else
			Profile:SetLocalizaitonValue("update_is_allowed", "false")
			local date=os.date("*t")
			Profile:SetLocalizaitonValue("last_update_date", tostring(date.day.."."..date.month.."."..date.year))
			if FoundSomeDifference then
				DoTranslateSTRINGStoRussian()
				BuildNewPO()
			end
			local datestring=date.day.."."..date.month.."."..date.year.." "..date.hour..":"..date.min..":"..date.sec
			self.CloseButton:SetText("Продолжить")
			local f=io.open(RussificationStorePath..RussianUpdateLogFileName,"r") --читаем то, что было в логе
			local olddata={}
			if f then
				for line in f:lines() do
					table.insert(olddata,escapeR(line).."\n")
				end
				f:close()
			end
			f=assert(io.open(RussificationStorePath..RussianUpdateLogFileName,"w")) --пишем то, что было и новые данные
			for _,line in ipairs(olddata) do
				f:write(line)
			end
			f:write("\n\n\n\n\n------------------------------------------------------------------------------------------\n")
			f:write("-------------------------------------"..datestring.."----------------------------------\n")
			f:write("------------------------------------------------------------------------------------------\n\n")
			f:write(downloadlog)
			f:close()
			if self.postfunction and type(self.postfunction)=="function" then self.postfunction() end
		end			
	end
	DoDownload() --начинаем загрузку из нотабеноида
end



function UpdateRussianDialog:OnControl(control, down)

    if UpdateRussianDialog._base.OnControl(self,control, down) then return true end
    
    if control == CONTROL_CANCEL and not down then    
            self.cb()
            return true
    end
end


function UpdateRussianDialog:Close()
	self.wasclosed=true
	TheFrontEnd:PopScreen(self)
end

function UpdateRussianDialog:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
--	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.OPTIONS.CLOSE)	
  --  end
	return table.concat(t, "  ")
end

return UpdateRussianDialog