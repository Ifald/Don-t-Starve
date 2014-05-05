GLOBAL.russianmodpath=MODROOT--����� ��� ������� �� ������ �������
GLOBAL.RussificationVersion=modinfo.version
GLOBAL.RussificationURL="http://notabenoid.com/book/45556/"
GLOBAL.russianmoddescription = "����������� ����, ���������� �� ������ ����������� �� �������� ������. ������� �������������� �� ����� www.notabenoid.com"

--����, �� �������� ����� ����������� ������� ������ po ����� � ���� ����������.
--�� ����� ������, ��� ������ ��� ������������� ���� �������� ��� ����� � ����� ���� �� ������ �� �����.
GLOBAL.RussificationStorePath="scripts/languages/"

local pofilename="russian.po"
GLOBAL.russianpofilename=pofilename

io=GLOBAL.io
STRINGS=GLOBAL.STRINGS
tonumber=GLOBAL.tonumber
tostring=GLOBAL.tostring
assert=GLOBAL.assert
GetPlayer=GLOBAL.GetPlayer
GLOBAL.RussianUpdateLogFileName="updatelog.txt"




function GLOBAL.escapeR(str) --������� \r �� ����� ������. ����� ��� �����, ����������� � ������.
	if string.sub(str,#str)=="\r" then return string.sub(str,1,#str-1) else return str end
end
local escapeR=GLOBAL.escapeR




local function GetPoFileVersion(file) --���������� ������ po �����
	local f = assert(io.open(file),"r")
	local ver=nil
	for line in f:lines() do
		ver=string.match(escapeR(line),"#%s+������%s+(.+)%s*$")
		if ver then break end
	end
	f:close()
	if not ver then ver="�� ������" end
	return ver
end

--���� ����� ������ ���� ��� ����������� �� � ����, �� ���������, ���� �� ��� ���, � ���� ���, �� ��������
if GLOBAL.RussificationStorePath and GLOBAL.RussificationStorePath~=MODROOT then
	local function copyfile(source,dest) --�������� ���� �� source � dest. ��� ���� ������ ��������� ��� �����.
		local f = assert(io.open(source,"rb"))
		local content = f:read("*all")
		f:close()
		f = assert(io.open(dest,"w"))
		f:write(content)
		f:close()
	end
	--��������� po ����
	if GLOBAL.kleifileexists(MODROOT..pofilename)
	   and (not GLOBAL.kleifileexists(GLOBAL.RussificationStorePath..pofilename) or GetPoFileVersion(GLOBAL.RussificationStorePath..pofilename)~=modinfo.version) then
		copyfile(MODROOT..pofilename,GLOBAL.RussificationStorePath..pofilename)
	end
	--��������� ��� ����
	if GLOBAL.kleifileexists(MODROOT..GLOBAL.RussianUpdateLogFileName)
	   and not GLOBAL.kleifileexists(GLOBAL.RussificationStorePath..GLOBAL.RussianUpdateLogFileName) then
		copyfile(MODROOT..GLOBAL.RussianUpdateLogFileName,GLOBAL.RussificationStorePath..GLOBAL.RussianUpdateLogFileName)
	end
	--��������� ��������, ���� ����� �� �������� ���� po
	if not GLOBAL.kleifileexists(GLOBAL.RussificationStorePath..pofilename) then
		GLOBAL.RussificationStorePath=MODROOT
	end
end

--��������� ������ �� �����, � ���� ��� �� ������������� ������� ������, �� ��������� �������
local poversion=GetPoFileVersion(GLOBAL.RussificationStorePath..pofilename)
if poversion~=modinfo.version then
	local OldStart=GLOBAL.Start --�������������� �������, ����� ���������� ������� ����� ����� ������� �����.
	function Start() 
		OldStart()
		local a,b="/","\\"
		if GLOBAL.PLATFORM == "NACL" or GLOBAL.PLATFORM == "PS4" or GLOBAL.PLATFORM == "LINUX_STEAM" or GLOBAL.PLATFORM == "OSX_STEAM" then
			a,b=b,a
		end
		local text="������ ����: "..modinfo.version..", ������ PO �����: "..poversion.."\n����: "..string.gsub(GLOBAL.CWD..GLOBAL.RussificationStorePath,a,b)..pofilename.."\n������� ������ ��������."
		local PopupDialogScreen = GLOBAL.require "screens/popupdialog"
	        GLOBAL.TheFrontEnd:PushScreen(PopupDialogScreen("�������� ������ PO �����", text,
			{{text="�������", cb = function() GLOBAL.TheFrontEnd:PopScreen() end}}))
	end
	GLOBAL.Start=Start
	return
end


--������� ��������� ���� language.lua �� ������� ������������ po ����� � ������ ������ �����������
function language_lua_has_rusification(filename)
--	local filename="scripts/languages/language.lua"
	if not GLOBAL.kleifileexists(filename) then return false end --��� �����? ��� �������


	local f = assert(io.open(filename,"r")) --������ ���� ���� � �����
	local content =""
	for line in f:lines() do
		content=content..line
--		table.insert(content)
	end
	f:close()

	content=string.gsub(content,"\r","")--������� ��� �������� �������, �� ������, ���� ��� �����
	content=string.gsub(content,"%-%-%[%[.-%]%]","")--������� ������������� �����������
	if string.sub(content,#content)~="\n" then content=content.."\n" end --��������� ������� ������ � ����� �����, ���� �����
	local tocomment={}
	for str in string.gmatch(content,"([^\n]*)\n") do --������� ��� ������
		if not str then str="" end
		str=string.gsub(str,"%-%-.*$","")--������� ��� ������������ �����������
		--���������� ������, ������� ����� ���������
		if string.find(str,"LanguageTranslator:LoadPOFile(",1,true) then table.insert(tocomment,str) end --�������� po
		if string.find(str,"russian_fix",1,true) then table.insert(tocomment,str) end --�������� ���� ������ ������ �����������
	end
	if #tocomment==0 then return false end --���� �� ������� �����, ������� ����� ����������������, �� �������

	content={}
	local f=assert(io.open(filename,"r"))
	for line in f:lines() do --����� ��������� ��� ������, ����������� ��������
		for _,str in ipairs(tocomment) do --������� ��� ������, ������� ����� ����������������
			local a,b=string.find(line,str,1,true)
			if a then --���� ���� ���������� ��...
				line=string.sub(line,1,a-1).."--"..str..string.sub(line,b+1)
				break --������������ � ��������� ����
			end
		end
		table.insert(content,line)
	end
	f:close()
	f = assert(io.open(filename,"w")) --��������� ����� language.lua � ������������ ��������
	for _,str in ipairs(content) do
		f:write(str.."\n")
	end
	f:close()
	return true
end
local languageluapath ="scripts/languages/language.lua"

if language_lua_has_rusification(languageluapath) then --���� � language.lua ������������ �����������
	local OldStart=GLOBAL.Start --�������������� �������, ����� ���������� ������� ����� ����� ������� ����� � ���������������
	function Start() 
		OldStart()
		local a,b="/","\\"
		if GLOBAL.PLATFORM == "NACL" or GLOBAL.PLATFORM == "PS4" or GLOBAL.PLATFORM == "LINUX_STEAM" or GLOBAL.PLATFORM == "OSX_STEAM" then
			a,b=b,a
		end
		local text="� ����� "..string.gsub("data/"..languageluapath,a,b).."\n������� ����������� ������ �����������.\n��� ����������� ���� ��������������."
		local PopupDialogScreen = GLOBAL.require "screens/popupdialog"
	        GLOBAL.TheFrontEnd:PushScreen(PopupDialogScreen("���������� ����������� �����������", text,
			{{text="�������", cb = function() GLOBAL.TheFrontEnd:PopScreen() GLOBAL.SimReset() end}}))
	end
	GLOBAL.Start=Start
end








--���������� ������� �������� � ������ ��������� �� �������
AddClassPostConstruct("screens/consolescreen", function(self) --��������� ������� ������ � �������� ��-�� ������ ������ �������� � ���� �������
	local NewConsoleValidChars=[[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"�������������������������������������Ũ�������������������������߲�������]]
	self.console_edit:SetCharacterFilter( NewConsoleValidChars )
end)


Assets={
	Asset("ATLAS",MODROOT.."images/gradient.xml"), --�������� �� ������� ������� ������� ���� � ���������� ��������
	Asset("ATLAS",MODROOT.."images/rus_mapgen.xml"), --���������������� ����������� � ���� ������������� ������ ����
	--���������
	Asset("ATLAS",MODROOT.."images/rus_locked.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_wickerbottom.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_waxwell.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_willow.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_wilson.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_woodie.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_wes.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_wolfgang.xml"), 
	Asset("ATLAS",MODROOT.."images/rus_wendy.xml"), 
	--
	Asset("ATLAS",MODROOT.."images/eyebutton.xml") --������ � ������
	}




--� ���� ������� ���������� ��������, ����������� � ���������� ������� �������
function ApplyRussianFonts()
	--����� �������, ������� ����� ���������.
	local RusFontsFileNames={"talkingfont__ru.zip",
				 "stint-ucr50__ru.zip",
				 "stint-ucr20__ru.zip",
				 "opensans50__ru.zip",
				 "belisaplumilla50__ru.zip",
				 "belisaplumilla100__ru.zip",
				 "buttonfont__ru.zip"}

	--���� ��������: ������� ��������� ������, ���� ��� ���� ���������

	--���������� � ���������� ���������� ������� ������ ������, ������� ����� ��������,
	--����� �� �������� ��� ������������
	GLOBAL.DEFAULTFONT = "opensans"
	GLOBAL.DIALOGFONT = "opensans"
	GLOBAL.TITLEFONT = "bp100"
	GLOBAL.UIFONT = "bp50"
	GLOBAL.BUTTONFONT="buttonfont"
	GLOBAL.NUMBERFONT = "stint-ucr"
	GLOBAL.TALKINGFONT = "talkingfont"
	GLOBAL.TALKINGFONT_WATHGRITHR = "talkingfont_wathgrithr"
	GLOBAL.SMALLNUMBERFONT = "stint-small"
	GLOBAL.BODYTEXTFONT = "stint-ucr"

	--��������� �����, � ������ ��� ����
	for i,FileName in ipairs(RusFontsFileNames) do
		GLOBAL.TheSim:UnloadFont("rusfont"..tostring(i))
	end
	GLOBAL.TheSim:UnloadPrefabs({"rusfonts"})


	--���� ��������: ��������� ������ �� �����

	--��������� ������ �������
	local RusFontsAssets={}
	for i,FileName in ipairs(RusFontsFileNames) do 
		table.insert(RusFontsAssets,GLOBAL.Asset("FONT",MODROOT.."fonts/"..FileName))
	end

	--������ ������, ����������� ��� � ���������
	local RusFontsPrefab=GLOBAL.Prefab("common/rusfonts", nil, RusFontsAssets)
	GLOBAL.RegisterPrefabs(RusFontsPrefab)
	GLOBAL.TheSim:LoadPrefabs({"rusfonts"})

	--��������� ������ ��������� � ������� �������
	for i,FileName in ipairs(RusFontsFileNames) do
		GLOBAL.TheSim:LoadFont(MODROOT.."fonts/"..FileName, "rusfont"..tostring(i))
	end
	--��������� � ���������� ���������� ������� ���� ������
	GLOBAL.DEFAULTFONT = "rusfont4"
	GLOBAL.DIALOGFONT = "rusfont4"
	GLOBAL.TITLEFONT = "rusfont6"
	GLOBAL.UIFONT = "rusfont5"
	GLOBAL.BUTTONFONT= "rusfont7"
	GLOBAL.NUMBERFONT = "rusfont2"
	GLOBAL.TALKINGFONT = "rusfont1"
	GLOBAL.SMALLNUMBERFONT = "rusfont3"
	GLOBAL.BODYTEXTFONT = "rusfont2"

end


GLOBAL.getmetatable(GLOBAL.TheSim).__index.UnregisterAllPrefabs = (function()
	local oldUnregisterAllPrefabs = GLOBAL.getmetatable(GLOBAL.TheSim).__index.UnregisterAllPrefabs
	return function(self, ...)
		oldUnregisterAllPrefabs(self, ...)
		ApplyRussianFonts()
	end
end)()

ApplyRussianFonts()

--��������� �������, ������������ ������� ������
local OldRegisterPrefabs=GLOBAL.ModManager.RegisterPrefabs --��������� �������,� ������� ����� ���������� ������ � ��������� ���������� ��������� ���������
local function NewRegisterPrefabs(self)
	OldRegisterPrefabs(self)
	ApplyRussianFonts()
end
GLOBAL.ModManager.RegisterPrefabs=NewRegisterPrefabs

--���������� ���������� ������� ������ � ���� �������� ������ ����
AddClassPostConstruct("screens/worldgenscreen", function(self)
	ApplyRussianFonts()
	--��������� ��� ��������� ��������, ������� ������ ������������������
	self.worldgentext:SetFont(GLOBAL.TITLEFONT)
	self.flavourtext:SetFont(GLOBAL.UIFONT)
end)




function GLOBAL.ChaptersListInit()
	return {
	{id="181337", text="���� � ���������",			name="ui"},
	{id="181142", text="������� ���������",			name="speech_maxwell"},
	{id="181335", text="������� ����", 			name="speech_woodie"},
	{id="181143", text="������� �����",			name="speech_wendy"},
	{id="181144", text="������� �����������",		name="speech_wickerbottom"},
	{id="181145", text="������� ������",			name="speech_willow"},
	{id="181333", text="������� �������",			name="speech_wilson"},
	{id="181334", text="������� ����������",		name="speech_wolfgang"},
	{id="181336", text="������� WX-78",			name="speech_wx78"},
	{id="181210", text="�������������� �����",		name="misc"},
	{id="181139", text="�������� ���������",		name="names"},
	{id="181132", text="������� ��������",			name="actions"},
	{id="181155", text="����� ������",			name="animalnames"},
	{id="181156", text="������� ������",			name="animaltalks"},
	{id="181135", text="�������� ����������",		name="character"},
	{id="181136", text="������� ������ ����",		name="lucy"},
	{id="181137", text="�������������� ������� ���������",	name="maxwell_misc"},
	{id="181140", text="�������� ��������",			name="recipies"}  
	}
end
GLOBAL.chapterslist=GLOBAL.ChaptersListInit()


GLOBAL.UpdatePeriod={"OncePerLaunch","OncePerDay","OncePerWeek","OncePerMonth","Never"}


--�������� ������������ ���������� ��������� � ������ �������� �������� str1 � ������������ �������� action
function rebuildname(str1,action,objectname)
	local function repsubstr(str,pos,substr)--�������� ��������� substr � ������ str � ������� pos
		pos=pos-1
		return string.sub(str,1,pos)..substr..string.sub(str,pos+#substr+1,#str)
	end
	if not str1 then
		return nil
	end
	local 	sogl=  {['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,
			['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1,['�']=1}
	local resstr=""
	local delimetr
	local wasnoun=false
	for str in string.gmatch(str1.." ","[�-��-���A-Za-z0-9%%'%.]+[%s-]") do
		delimetr=string.sub(str,#str)
		str=string.sub(str,1,#str-1)
		if action=="WALKTO" then --���� �
			if string.sub(str,#str-1)=="��" and resstr=="" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"���")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"���")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"���")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"���")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str-1)=="��" and resstr=="" then
				str=repsubstr(str,#str-1,"���")
			elseif string.sub(str,#str-1)=="��" and resstr=="" then
				str=repsubstr(str,#str-1,"���")
			elseif string.sub(str,#str-2)=="���" then
				str=string.sub(str,1,#str-3).."��"
			elseif string.sub(str,#str-1)=="��" then
				str=string.sub(str,1,#str-2).."��"
				wasnoun=true
			elseif string.sub(str,#str-2)=="���" then
				str=string.sub(str,1,#str-3).."��"
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" then
				str=str.."�"
			elseif string.sub(str,#str-1)=="��" and not wasnoun then
				str=repsubstr(str,#str,"��")
				wasnoun=true
			elseif string.sub(str,#str)=="�" and not wasnoun then
				str=repsubstr(str,#str,"��")
				wasnoun=true
			elseif string.sub(str,#str)=="�" and not wasnoun then
				str=repsubstr(str,#str,"��")
				wasnoun=true
			elseif string.sub(str,#str)=="�" and not wasnoun then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str)=="�" and not wasnoun then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str)=="�" and not wasnoun then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif string.sub(str,#str-1)=="��" and not wasnoun then
				str=repsubstr(str,#str-1,"��")
				wasnoun=true
			elseif string.sub(str,#str)=="�" and not wasnoun then
				str=repsubstr(str,#str,"�")
				wasnoun=true
			elseif sogl[string.sub(str,#str)] and not wasnoun then
				str=str.."�"
				wasnoun=true
			end
		elseif action and objectname and (objectname=="pigman" or objectname=="bunnyman") then --������� ������������� � ����� ������ ��� �������
			if string.sub(str,#str-2)=="���" then
				str=string.sub(str,1,#str-2).."��"
			elseif string.sub(str,#str-2)=="���" then
				str=string.sub(str,1,#str-2).."���"
			elseif string.sub(str,#str-2)=="���" then
				str=string.sub(str,1,#str-2).."���"
			elseif string.sub(str,#str-1)=="��" then
				str=string.sub(str,1,#str-2).."��"
			elseif string.sub(str,#str)=="�" then
				str=string.sub(str,1,#str-1).."�"
			elseif string.sub(str,#str)=="�" then
				str=string.sub(str,1,#str-1).."�"
			elseif string.sub(str,#str)=="�" then
				str=string.sub(str,1,#str-1).."�"
			elseif string.sub(str,#str)=="�" then
				str=string.sub(str,1,#str-1).."�"
			elseif sogl[string.sub(str,#str)] then
				str=str.."�"
			end
		elseif action then --�������
			if string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str-1)=="��" then
				str=repsubstr(str,#str-1,"��")
			elseif string.sub(str,#str)=="�" then
				str=repsubstr(str,#str,"�")
			elseif string.sub(str,#str)=="�" then
				str=repsubstr(str,#str,"�")
			end
		end
		resstr=resstr..str..delimetr
	end
	resstr=string.sub(resstr,1,#resstr-1)
	return resstr
end
GLOBAL.testname=function(name)
	print("���� � "..rebuildname(name,"WALKTO"))
	print("��������� "..rebuildname(name,"DEFAULTACTION"))
end


--��������� � ����� fn ��� ����� � ���������, ��������� � ��������� action)
local function printnames(fn,action)
	local filename = MODROOT..fn..".txt"
	local str1,str2
	local names={}
	local f=assert(io.open(MODROOT.."names_new.txt","r"))
	for line in f:lines() do
		str1=string.match(line,"%.([^.]*)$")
		str2=STRINGS.NAMES[str1]
		local s1
		if action=="DEFAULTACTION" then
			s1="������� "
		elseif action=="WALKTO" then
			s1="���� � "
		end
		s1=s1..rebuildname(str2,action)
		local name=s1
		local len=#s1
		while len<48 do
			name=name.."\t"
			len=len+8
		end
		s1=str2
		name=name..s1
		len=#s1
		while len<48 do
			name=name.."\t"
			len=len+8
		end
		name=name..str1.."\n"
		table.insert(names,name)
	end
	f:close()
	local file = io.open(filename, "w")
	for i,v in ipairs(names) do
		file:write(v)
	end
	file:close()
end



GLOBAL.russiannames={} --������� � ������� ������� �������� ��������� � ��������� �������
GLOBAL.actionstosave={} --������� ��������� ��-�� �����, �� �������� �������� � ����� ��� ���������� po

GLOBAL.shouldbecapped={} --�������, � ������� ��������� ������ ��������, ������ ����� ������� ������� � ������� ����� ��� ���������.

--��������� ������ ���, ������� ������ ���������� � ��������� �����. ������ ������ �������� �� �������� ��������.
local function loadcappednames(data)
	GLOBAL.shouldbecapped={}
	local filename = GLOBAL.RussificationStorePath..pofilename
	if (data and #data==0) or not GLOBAL.kleifileexists(filename) then return nil end
	local insection=false
	local function parseline(line)
		line=escapeR(line)
		if string.sub(line,1,10)=="# --------" then
			insection=string.find(line,"������ ���������� � ��������� �����",1,true)
		elseif insection and string.sub(line,1,1)=="#" then
			GLOBAL.shouldbecapped[string.sub(line,2):lower()]=true
		end
	end
	if data then
		for _,line in ipairs(data) do
			parseline(line)
		end
	else
		local f=assert(io.open(filename,"r"))
		for line in f:lines() do
			parseline(line)
		end
		f:close()
	end
end
GLOBAL.loadcappednames=loadcappednames

--��������� ������������ ��������� ��������� � ������ ������ �� po �����. ���� ������� data, �� �������� ���
function loadfixednames(BuildErrorLog, data)
	GLOBAL.russiannames={}
	GLOBAL.actionstosave={}

	local filename = GLOBAL.RussificationStorePath..pofilename

	if (data and #data==0) or not GLOBAL.kleifileexists(filename) then return nil end

	local action=nil
	local predcessorword=""
	local f,errorlog=nil,{}
	if BuildErrorLog then f=assert(io.open(MODROOT.."FixedNamesErrors.txt","w")) end

	local function parseline(line)
		line=escapeR(line)
		if string.sub(line,1,10)=="# --------" then --�������� ���������� ������� � ����� �� ��������
			action=string.match(line,"��������%s+(.*)%s*$") --�������� ��������� �������� ��������
			if action then
				action=action:upper()
				if action=="DEFAULTACTION" then
					predcessorword="�������"
				elseif action=="WALKTO" then
					predcessorword="���� �"
				else --��� ������ ��������
					predcessorword=GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.ACTIONS."..action] or ""
				end
				GLOBAL.actionstosave[action]={} --������ ������� � ������� ���� ��������.
			end
		elseif action and line~="" and string.sub(line,1,1+#predcessorword)=="#"..predcessorword then
			local translation=string.match(line,predcessorword.." (.-)\t") 
			local original=string.match(line,"\t([^\t]+)\t") 
			local path=string.match(line,"\t([^\t]-)$")
			if BuildErrorLog and path~="OTHER" then
				if not STRINGS.NAMES[path] and not errorlog[path] then
					f:write("�� ������ ������� "..tostring(path).."\n")
					errorlog[path]=true
				elseif GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.NAMES."..path]~=original and not errorlog[path] then
					f:write("�� notabenoid ���������� �������� �������� "..tostring(original).." ("..tostring(path)..")".." �� "..GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.NAMES."..path].."\n")
					errorlog[path]=true
				end
			end
			table.insert(GLOBAL.actionstosave[action],{pth=path,trans=translation,orig=original})
			if GLOBAL.russiannames[original] then
				GLOBAL.russiannames[original][action]=translation
			else
				GLOBAL.russiannames[original]={}
				GLOBAL.russiannames[original]["DEFAULT"]=STRINGS.NAMES[path] --��������� ������������ ��� �� ��
				GLOBAL.russiannames[original].path=path --��������� ����
				if action~="DEFAULTACTION" then
					GLOBAL.russiannames[original]["DEFAULTACTION"]=rebuildname(original,"DEFAULTACTION")
				end
				if action~="WALKTO" then
					GLOBAL.russiannames[original]["WALKTO"]=rebuildname(original,"WALKTO")
				end
				GLOBAL.russiannames[original][action]=translation
			end
		end
	end
	if data then
		for _,line in ipairs(data) do
			parseline(line)
		end
	else
		local f=assert(io.open(filename,"r"))
		for line in f:lines() do
			parseline(line)
		end
		f:close()
	end
	if BuildErrorLog then f:close() end
end
GLOBAL.loadfixednames=loadfixednames


GLOBAL.perishablerus={} --������� � ������������� ���������� ���������
GLOBAL.perishableforsave={} --������� ��������� ��-�� �����, �� �������� �������� � ����� ��� ���������� � ���������� ������������������
                                    
--��������� �� po ����� ������ ���������� ����-������� ��� ���������
function LoadFixedAdjectives(data)
	GLOBAL.perishablerus={}
	GLOBAL.perishableforsave={}
	local filename = GLOBAL.RussificationStorePath..pofilename
	if (data and #data==0) or not GLOBAL.kleifileexists(filename) then return nil end
	GLOBAL.perishablerus["STALE"]=GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.UI.HUD.STALE"] or "Stale"
	GLOBAL.perishablerus["SPOILED"]=GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.UI.HUD.SPOILED"] or "Spoiled"
	local insection=false
	local function parseline(line)
		line=escapeR(line)
		if string.sub(line,1,10)=="# --------" then
			insection=string.find(line,"perishable",1,true)
		elseif insection and string.sub(line,1,7)=="#������" then
			table.insert(GLOBAL.perishableforsave,line)
			local stale=string.match(string.sub(line,2),"(.-)\t") 
			local spoiled=string.match(line,"\t([^\t]+)\t") 
			local original=string.match(line,"\t.+\t([^\t]+)\t") 
			local path=string.match(line,"\t([^\t]-)$") 
			GLOBAL.perishablerus[original]={STALE=stale,SPOILED=spoiled}
		end
	end
	if data then
		for _,line in ipairs(data) do
			parseline(line)
		end
	else
		local f=assert(io.open(filename,"r"))
		for line in f:lines() do
			parseline(line)
		end
		f:close()
	end
end
GLOBAL.LoadFixedAdjectives=LoadFixedAdjectives



--������ ����� �������� ������ ����
local UPDATENAME=GLOBAL.STRINGS.UI.MAINSCREEN.UPDATENAME

--��������� �����������
LoadPOFile(GLOBAL.RussificationStorePath..pofilename, "ru")

--��������������� �������� ������ ���� �� ������
GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.UI.MAINSCREEN.UPDATENAME"]=UPDATENAME

--���������� � � STRINGS
GLOBAL.TranslateStringTable(GLOBAL.STRINGS)



loadcappednames() --��������� �����, ������� ������ ���������� ����������. ������ ���� ����� ����������� �������� � STRINGS

LoadFixedAdjectives() --��������� ������������ �������� ���������

loadfixednames(false) --��������� ���������� ���������


--printnames("datelniy","DEFAULTACTION")
--printnames("tworitelniy","WALKTO")

--���������� �������, ���������� � ��������� ������ ������ �������, � ������� �� ������ ���� ��������� ��������������
local function find_wilson_unigender_strings(include_translation)
	local f=assert(io.open(MODROOT.."wilson_unigender_strings.txt","w"))
	local wendy,wickerbottom,willow={},{},{}
	for key,val in pairs(GLOBAL.LanguageTranslator.languages["ru"]) do --���� ������� �������
		if string.sub(key,1,24)=="STRINGS.CHARACTERS.WENDY" then wendy[key]=val end
		if string.sub(key,1,31)=="STRINGS.CHARACTERS.WICKERBOTTOM" then wickerbottom[key]=val end
		if string.sub(key,1,25)=="STRINGS.CHARACTERS.WILLOW" then willow[key]=val end
	end
	for key,val in pairs(GLOBAL.LanguageTranslator.languages["ru"]) do
		if string.sub(key,1,26)=="STRINGS.CHARACTERS.GENERIC" then --���� ��� ����� �������
			if not wendy["STRINGS.CHARACTERS.WENDY"..string.sub(key,27)] or --� � ��� � ������ �� ������� ����������
			   not wickerbottom["STRINGS.CHARACTERS.WICKERBOTTOM"..string.sub(key,27)] or
			   not willow["STRINGS.CHARACTERS.WILLOW"..string.sub(key,27)] then --�� ��������� �
				f:write(key)
				if not wendy["STRINGS.CHARACTERS.WENDY"..string.sub(key,27)] then f:write(" ��� � Wendy") end
				if not wickerbottom["STRINGS.CHARACTERS.WICKERBOTTOM"..string.sub(key,27)] then f:write(" ��� � Wickerbottom") end
				if not willow["STRINGS.CHARACTERS.WILLOW"..string.sub(key,27)] then f:write(" ��� � Willow") end
				f:write("\n")
				if include_translation then f:write(val.."\n\n") end
			end
		end
	end
	f:close()
end

--find_wilson_unigender_strings(true)

--���������� �������, ��������� ����� ���� ������ � ���������� � ���� AnimalNamesCheck.txt
--����� ��� �������� ������������ ��������� ���
local function AnimalNamesCheck()
	local f=assert(io.open(MODROOT.."AnimalNamesCheck.txt","w"))
	f:write("------------�����-------------\n\n")
	for key,name in pairs(STRINGS.BUNNYMANNAMES) do
		f:write(key.." "..name..":\n")
		f:write("\t���� � "..rebuildname(name,"WALKTO","bunnyman").."\n")
		f:write("\t��������� "..rebuildname(name,"DEFAULTACTION","bunnyman").."\n")
	end	
	f:write("\n------------������-------------\n\n")
	for key,name in pairs(STRINGS.PIGNAMES) do
		f:write(key.." "..name..":\n")
		f:write("\t���� � "..rebuildname(name,"WALKTO","pigman").."\n")
		f:write("\t��������� "..rebuildname(name,"DEFAULTACTION","pigman").."\n")
	end	
	f:close()
end

--AnimalNamesCheck()




--����� ������ �������, �������� �������� ��������
function GetAdjectiveNew(self)
	local function fixadjective(adjective,name)
		if GLOBAL.perishablerus[name] then
			if adjective==GLOBAL.perishablerus["STALE"] then
				adjective=GLOBAL.perishablerus[name]["STALE"]
			elseif adjective==GLOBAL.perishablerus["SPOILED"] then
				adjective=GLOBAL.perishablerus[name]["SPOILED"]
			end
		end
		return adjective
	end
	for k,v in pairs(self.components) do
		if v.GetAdjective then
			local str = v:GetAdjective()
			if str then
				if self.name then
					return fixadjective(str,self.name)
				else
					return str
				end
			end
		end
	end
end
GLOBAL.EntityScript["GetAdjective"]=GetAdjectiveNew --��������� �������, ��������� �������� ���������



local GetDisplayNameOld=GLOBAL.EntityScript["GetDisplayName"] --��������� ������ �������, ��������� �������� ��������
function GetDisplayNameNew(self) --������� �������, ��������� �������� ��������. � ��� ����������� ��������� � ����������� �� �������� (���������� �ct)
	local name=GetDisplayNameOld(self)

	                       
	local act=GetPlayer().components.playercontroller:GetLeftMouseAction() --�������� ������� ��������
	local itisblueprint=false
	if name:sub(-10)==" Blueprint" then --������ �������������� ��������� ��� ��������
		name=name:sub(1,-11)
		itisblueprint=true
	end
	if act then
		act=act.action.id
		if GLOBAL.russiannames[name] then
			name=GLOBAL.russiannames[name][act] or GLOBAL.russiannames[name]["DEFAULTACTION"] or GLOBAL.russiannames[name]["DEFAULT"] or rebuildname(name,act,self.prefab) or "NAME"
		else
			name=rebuildname(name,act,self.prefab)
		end
		if not itisblueprint and self.prefab and self.prefab~="pigman" and self.prefab~="bunnyman" and not GLOBAL.shouldbecapped[self.prefab] and name and type(name)=="string" and #name>0 then --������ ������ ������ �������� �������� � ������ �������
			local firstletter=string.byte(name)
			if firstletter>=0xC0 and firstletter<0xE0 then firstletter=firstletter+0x20
				elseif firstletter==0xA8 then firstletter=firstletter+0x10 end
			name=(string.char(firstletter)):lower()..string.sub(name,2)
		end
		if itisblueprint then name="����� �������� \""..name.."\"" end
	else
	        if itisblueprint then name="����� �������� \""..name.."\"" end
	end
    return name
end
GLOBAL.EntityScript["GetDisplayName"]=GetDisplayNameNew --��������� �� �����



--�������������� �������, ��������� "������� ...", ����� ��������������� �� ����� �����-������� ���� �������.
local OldGetHoverTextOverride
function NewGetHoverTextOverride(self)
	if self.placer_recipe then
		local name=STRINGS.NAMES[string.upper(self.placer_recipe.name)]
		local act="BUILD"
		if name then
			if GLOBAL.russiannames[name] then
				name=GLOBAL.russiannames[name][act] or GLOBAL.russiannames[name]["DEFAULTACTION"] or GLOBAL.russiannames[name]["DEFAULT"] or rebuildname(name,act) or STRINGS.UI.HUD.HERE
			else
				name=rebuildname(name,act) or STRINGS.UI.HUD.HERE
			end
		else
			name=STRINGS.UI.HUD.HERE
		end
		if not GLOBAL.shouldbecapped[self.placer_recipe.name] and name and type(name)=="string" and #name>0 then --������ ������ ������ �������� �������� � ������ �������
			local firstletter=string.byte(name)
			if firstletter>=0xC0 and firstletter<0xE0 then firstletter=firstletter+0x20
				elseif firstletter==0xA8 then firstletter=firstletter+0x10 end
			name=(string.char(firstletter)):lower()..string.sub(name,2)
		end
		return STRINGS.UI.HUD.BUILD.. " " .. name
	end
end
AddClassPostConstruct("components/playercontroller", function(self)
	GetHoverTextOverride=self["GetHoverTextOverride"]
	self["GetHoverTextOverride"]=NewGetHoverTextOverride
end)



local oldSelectPortrait --������ ������� ������ �������� � ���� ������ ���������
local function newSelectPortrait(self,portrait)
	oldSelectPortrait(self,portrait) --��������� ������������ �������
	if self.heroportait and self.heroportait.texture then
		local list={["locked"]=1,["wickerbottom"]=1,["waxwell"]=1,["willow"]=1,["wilson"]=1,["woodie"]=1,["wes"]=1,["wolfgang"]=1,["wendy"]=1}
		local name=string.sub(self.heroportait.texture,1,-5)
		if list[name] then
			self.heroportait:SetTexture("images/rus_"..name..".xml", "rus_"..name..".tex")
		end
	end
end
--��������� ������� ������ �������� � ���� ������ ���������
AddClassPostConstruct("screens/characterselectscreen", function(self)
	oldSelectPortrait=self["SelectPortrait"]
	self["SelectPortrait"]=newSelectPortrait
	self:SelectPortrait(1) --�����, ����� �������� ��, ��� ��� ������ ����������
end)




local oldRefreshOptions --������ ������� ���������� ����� � ���� �������� �����
local function newRefreshOptions(self) --����� �������
	oldRefreshOptions(self) --��������� ������������ �������
	if self.optionspanel then
		local list={["day.tex"]=1,["season.tex"]=1,["season_start.tex"]=1,["world_size.tex"]=1,["world_branching.tex"]=1,["world_loop.tex"]=1}
		for v in pairs(self.optionspanel:GetChildren()) do --���������� ������
			if tostring(v)=="option" then
				for prefab in pairs(v:GetChildren()) do --���� �������� � ������� � ������
					if prefab.name and prefab.name:upper()=="IMAGE" then
						if list[prefab.texture] then
							prefab:SetTexture(MODROOT.."images/rus_mapgen.xml", "rus_"..prefab.texture)
						end
					elseif prefab.name and prefab.name:upper()=="SPINNER" and prefab.options then
						local shouldbeupdated=false
						for _,opt in ipairs(prefab.options) do --������� �����
							local words=string.split(opt.text," ") --��������� �� �����
							opt.text=words[1]
							if #words>1 then --���� ���� ���������
								if opt.text==STRINGS.UI.SANDBOXMENU.SLIDELONG then
									if words[2]==STRINGS.UI.SANDBOXMENU.DAY or words[2]==STRINGS.UI.SANDBOXMENU.DUSK then
										opt.text=opt.text:sub(1,-2).."�"
									elseif words[2]==STRINGS.UI.SANDBOXMENU.NIGHT or words[2]==STRINGS.UI.SANDBOXMENU.WINTER then
										opt.text=opt.text:sub(1,-3).."��"
									elseif words[2]==STRINGS.UI.SANDBOXMENU.SUMMER then
										opt.text=opt.text:sub(1,-3).."��"
									end
								end
								for i=2,#words do --��� ����������� � ��������� �����
									local firstletter=string.byte(words[i])
									if firstletter>=0xC0 and firstletter<0xE0 then firstletter=firstletter+0x20
									elseif firstletter==0xA8 then firstletter=firstletter+0x10 end
									words[i]=(string.char(firstletter)):lower()..string.sub(words[i],2)
									opt.text=opt.text.." "..words[i]
								end
								shouldbeupdated=true
							end
							
						end
						if shouldbeupdated then prefab:UpdateState() end
					end

				end
			end
		end
	end
end
--��������� ������� ���������� � ���������� ��������� ����� �����
AddClassPostConstruct("screens/customizationscreen", function(self)
	oldRefreshOptions=self["RefreshOptions"]
	self["RefreshOptions"]=newRefreshOptions
	self:RefreshOptions() --�����, ����� �������� ��, ��� ��� ������ ����������
end)




--���������� ������ � ������ ����
local OldShowMenu --������ ������� ������ ���� ��� mainscreen
function NewShowMenu(self,menu_items) --����� �������
	for i,v in ipairs(menu_items) do --���� ������ "����������", � ��������� ����� �� "�����������"
		if v.text==STRINGS.UI.MAINSCREEN.CONTROLS then
			local LanguageOptions = GLOBAL.require "screens/LanguageOptions"
			table.insert( menu_items, i+1, {text="�����������", cb= function() TheFrontEnd:PushScreen(LanguageOptions()) end})
			break
		end
	end
	OldShowMenu(self,menu_items) --��������� ������������ �������
end

AddClassPostConstruct("screens/mainscreen", function(self) --��������� �������, ����� ������������ ������ "�����������"
	OldShowMenu=self["ShowMenu"]
	self["ShowMenu"]=NewShowMenu
end)


--����������� ���� � ������� � ���������
AddClassPostConstruct("widgets/spinner", function(self, options, width, height, textinfo, ...) --��������� ������� ������ � �������� ��-�� ������ ������ �������� � ���� �������
	if textinfo then return end
	self.text:SetFont(GLOBAL.BUTTONFONT)
end)


--���������� ����� ������� ������� �� ������� � ������ � ���������.
AddClassPostConstruct("widgets/containerwidget", function(self)
	self.oldOpen=self.Open
	local function newOpen(self, container, doer)
		self:oldOpen(container, doer)
		if self.button then
			if self.button:GetText()=="Cook" then self.button:SetText("��������") end
			if self.button:GetText()=="Activate" then self.button:SetText("���������") end
		end
	end
	self.Open=newOpen
end)


AddClassPostConstruct("widgets/recipepopup", function(self) --��������� ����� �������� ������� � ������ ��������
	if not self.desc then return end
	self.desc:SetSize(28)
	self.desc:SetRegionSize(64*3+30,130)
end)


--����-���� ���������� ������� � ������� � ���� �������� ���
AddClassPostConstruct("screens/loadgamescreen", function(self)
	self.oldMakeSaveTile=self.MakeSaveTile
	local function newMakeSaveTile(self,slotnum)
		local item=self:oldMakeSaveTile(slotnum)
		item.portraitbg:SetPosition(-130 + 40, 2, 0)	
		item.portrait:SetPosition(-130 + 40, 2, 0)	
		if item.portraitbg.shown then item.text:SetPosition(50,0,0) end
		return item
	end
	self.MakeSaveTile=newMakeSaveTile
end)

--��������� ������ ������ � ��������� ������� ������
AddClassPostConstruct("screens/slotdetailsscreen", function(self)
	self.text:SetSize(47)
end)

--��������� ����� � ��������� �����
AddClassPostConstruct("screens/morguescreen", function(self) 
	if self.obits_titles then
		for str in pairs(self.obits_titles:GetChildren()) do
			if type(str)=="table" and str.name and str.name=="Text" then
				str:SetSize(28)
			end
		end
	end
end)


--��� ���, ��� ���������� ps4 ��� NACL ������ ���� ����������� ��������� �� � ��� �����, � � ������.
--��� ����� ������������ ���������� ������������ ������ PlayerProfile
local function SetLocalizaitonValue(self,name,value) --�����, ����������� ����� � ������ name � ��������� value
        local USE_SETTINGS_FILE = GLOBAL.PLATFORM ~= "PS4" and GLOBAL.PLATFORM ~= "NACL"
 	if USE_SETTINGS_FILE then
		TheSim:SetSetting("translation", tostring(name), tostring(value))
	else
		self:SetValue(tostring(name), tostring(value))
		self.dirty = true
		self:Save() --��������� �����, ��������� � ��� ��� ������ "���������"
	end
end
local function GetLocalizaitonValue(self,name) --�����, ������������ �������� ����� name
        local USE_SETTINGS_FILE = GLOBAL.PLATFORM ~= "PS4" and GLOBAL.PLATFORM ~= "NACL"
 	if USE_SETTINGS_FILE then
		return TheSim:GetSetting("translation", tostring(name))
	else
		return self:GetValue(tostring(name))
	end
end

--��������� ���������� PlayerProfile �������������� �������������� ���� ������� � �������� ��������� �������� ����� ������ ��������.
AddGlobalClassPostConstruct("playerprofile", "PlayerProfile", function(self)
        local USE_SETTINGS_FILE = GLOBAL.PLATFORM ~= "PS4" and GLOBAL.PLATFORM ~= "NACL"
 	if not USE_SETTINGS_FILE then
	        self.persistdata.update_is_allowed = true --��������� ��������� ���������� �� ���������
	        self.persistdata.update_frequency = GLOBAL.UpdatePeriod[3] --��� � ������ �� ���������
		local date=GLOBAL.os.date("*t")
		self.persistdata.last_update_date = tostring(date.day.."."..date.month.."."..date.year) --������� ���� �� ���������
	end
	self["SetLocalizaitonValue"]=SetLocalizaitonValue --����� ������ �������� �����
	self["GetLocalizaitonValue"]=GetLocalizaitonValue --����� ��������� �������� �����
end)



--��������� ����� �� �����������
local function DownloadNotabenoidChapters()
	local UpdateRussianDialog = GLOBAL.require "screens/UpdateRussianDialog"
	GLOBAL.TheFrontEnd:PushScreen(UpdateRussianDialog())
end


  

local OldStart=GLOBAL.Start
function Start() --����� ���������� ���� ������� ��� ����� ���������� �������.


	OldStart() --������� ��������� ������ �������

	local a=GLOBAL.Profile:GetLocalizaitonValue("update_is_allowed")
	
	if not a or a=="true" or a==true then --���� � ini ����� ���� ������, ����������� ��������� ���������� ��� � ������ ���
		local period=GLOBAL.Profile:GetLocalizaitonValue("update_frequency")
		if not period then --���� ��� ������ � �������, �� ������ �� ��������� ��� � ������
			period=GLOBAL.UpdatePeriod[3]
			GLOBAL.Profile:SetLocalizaitonValue("update_frequency",period)
		end
		if period==GLOBAL.UpdatePeriod[1] then --��� ������ �������
			DownloadNotabenoidChapters()
		end
		if period~=GLOBAL.UpdatePeriod[5] then --���� �� ������� "������� �� ���������"
			local date=GLOBAL.os.date("*t")
			local date2=GLOBAL.Profile:GetLocalizaitonValue("last_update_date")
			if date2 then --�������� ��� ����. ���������� � ����������� �� ������������� ������� ����������
				date2=string.split(date2,".")
				if period==GLOBAL.UpdatePeriod[2] then --��� � ����
					if date2[1]~=tostring(date.day) then
						DownloadNotabenoidChapters()
					end
				else
					local a=28
					if date.year%4==0 then a=29 end
					local DaystoMonth={0,31,31+a,31+a+31,31+a+31+30,31+a+31+30+31,31+a+31+30+31+30,31+a+31+30+31+30+31,31+a+31+30+31+30+31+31,31+a+31+30+31+30+31+31+30,31+a+31+30+31+30+31+31+30+31,31+a+31+30+31+30+31+31+30+31+30}
					local DaysperMonth={31,a,31,30,31,30,31,31,30,31,30,31}
					local datedaysum=tonumber(date.year)*365+DaystoMonth[tonumber(date.month)]+tonumber(date.day)
					local date2daysum=tonumber(date2[3])*365+DaystoMonth[tonumber(date2[2])]+tonumber(date2[1])
					if period==GLOBAL.UpdatePeriod[3] then --��� � ������
						if datedaysum-7>=date2daysum then
							DownloadNotabenoidChapters()
						end
					elseif period==GLOBAL.UpdatePeriod[4] then --��� � �����
						if datedaysum-DaysperMonth[tonumber(date2[2])]>=date2daysum then
							DownloadNotabenoidChapters()
						end
					end
				
				end
			else --��� ������ � ����. ������ ��� ������ ����� ������ ����������.
				DownloadNotabenoidChapters() 
			end
		end
	end
end
GLOBAL.Start=Start



--������������� ������� �������� ���� ��� ������ � ��� ���� ������ � ���, ��� ����� �����������
local oldshutdown=GLOBAL.Shutdown
function newShutdown()
	GLOBAL.Profile:SetLocalizaitonValue("update_is_allowed", "true") --���� ���� ��������� � ���������� �����, �������� � ��������� ��� ��������� ����������
	oldshutdown()
end
GLOBAL.Shutdown=newShutdown


