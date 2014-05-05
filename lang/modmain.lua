GLOBAL.russianmodpath=MODROOT--Нужно для доступа из других модулей
GLOBAL.RussificationVersion=modinfo.version
GLOBAL.RussificationURL="http://notabenoid.com/book/45556/"
GLOBAL.russianmoddescription = "Русификация игры, собираемая на основе голосований за переводы реплик. Перевод осуществляется на сайте www.notabenoid.com"

--Путь, по которому будут сохраняться рабочие версии po файла и лога обновлений.
--Он нужен потому, что сейчас при синхронизации стим затирает все файлы в папке мода на версии из стима.
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




function GLOBAL.escapeR(str) --Удаляет \r из конца строки. Нужна для строк, загружаемых в юниксе.
	if string.sub(str,#str)=="\r" then return string.sub(str,1,#str-1) else return str end
end
local escapeR=GLOBAL.escapeR




local function GetPoFileVersion(file) --Возвращает версию po файла
	local f = assert(io.open(file),"r")
	local ver=nil
	for line in f:lines() do
		ver=string.match(escapeR(line),"#%s+Версия%s+(.+)%s*$")
		if ver then break end
	end
	f:close()
	if not ver then ver="не задана" end
	return ver
end

--Если задан другой путь для складывания по и лога, то проверяем, есть ли они там, и если нет, то копируем
if GLOBAL.RussificationStorePath and GLOBAL.RussificationStorePath~=MODROOT then
	local function copyfile(source,dest) --копирует файл из source в dest. Оба пути должны содержать имя файла.
		local f = assert(io.open(source,"rb"))
		local content = f:read("*all")
		f:close()
		f = assert(io.open(dest,"w"))
		f:write(content)
		f:close()
	end
	--Проверяем po файл
	if GLOBAL.kleifileexists(MODROOT..pofilename)
	   and (not GLOBAL.kleifileexists(GLOBAL.RussificationStorePath..pofilename) or GetPoFileVersion(GLOBAL.RussificationStorePath..pofilename)~=modinfo.version) then
		copyfile(MODROOT..pofilename,GLOBAL.RussificationStorePath..pofilename)
	end
	--Проверяем лог файл
	if GLOBAL.kleifileexists(MODROOT..GLOBAL.RussianUpdateLogFileName)
	   and not GLOBAL.kleifileexists(GLOBAL.RussificationStorePath..GLOBAL.RussianUpdateLogFileName) then
		copyfile(MODROOT..GLOBAL.RussianUpdateLogFileName,GLOBAL.RussificationStorePath..GLOBAL.RussianUpdateLogFileName)
	end
	--Финальная проверка, если вдруг не создался файл po
	if not GLOBAL.kleifileexists(GLOBAL.RussificationStorePath..pofilename) then
		GLOBAL.RussificationStorePath=MODROOT
	end
end

--Проверяем версию по файла, и если она не соответствует текущей версии, то отключаем перевод
local poversion=GetPoFileVersion(GLOBAL.RussificationStorePath..pofilename)
if poversion~=modinfo.version then
	local OldStart=GLOBAL.Start --Переопределяем функцию, после выполнения которой можно будет вывести попап.
	function Start() 
		OldStart()
		local a,b="/","\\"
		if GLOBAL.PLATFORM == "NACL" or GLOBAL.PLATFORM == "PS4" or GLOBAL.PLATFORM == "LINUX_STEAM" or GLOBAL.PLATFORM == "OSX_STEAM" then
			a,b=b,a
		end
		local text="Версия игры: "..modinfo.version..", версия PO файла: "..poversion.."\nПуть: "..string.gsub(GLOBAL.CWD..GLOBAL.RussificationStorePath,a,b)..pofilename.."\nПеревод текста отключён."
		local PopupDialogScreen = GLOBAL.require "screens/popupdialog"
	        GLOBAL.TheFrontEnd:PushScreen(PopupDialogScreen("Неверная версия PO файла", text,
			{{text="Понятно", cb = function() GLOBAL.TheFrontEnd:PopScreen() end}}))
	end
	GLOBAL.Start=Start
	return
end


--Функция проверяет файл language.lua на наличие подлключения po файла и старых версий русификации
function language_lua_has_rusification(filename)
--	local filename="scripts/languages/language.lua"
	if not GLOBAL.kleifileexists(filename) then return false end --Нет файла? Нет проблем


	local f = assert(io.open(filename,"r")) --Читаем весь файл в буфер
	local content =""
	for line in f:lines() do
		content=content..line
--		table.insert(content)
	end
	f:close()

	content=string.gsub(content,"\r","")--Удаляем все возвраты каретки, на случай, если это юникс
	content=string.gsub(content,"%-%-%[%[.-%]%]","")--Удаляем многострочные комментарии
	if string.sub(content,#content)~="\n" then content=content.."\n" end --добавляем перенос строки в самом конце, если нужно
	local tocomment={}
	for str in string.gmatch(content,"([^\n]*)\n") do --Обходим все строки
		if not str then str="" end
		str=string.gsub(str,"%-%-.*$","")--Удаляем все однострочные комментарии
		--Запоминаем строки, которые нужно отключить
		if string.find(str,"LanguageTranslator:LoadPOFile(",1,true) then table.insert(tocomment,str) end --загрузка po
		if string.find(str,"russian_fix",1,true) then table.insert(tocomment,str) end --загрузка моей ранней версии русификации
	end
	if #tocomment==0 then return false end --Если не нашлось строк, которые нужно закомментировать, то выходим

	content={}
	local f=assert(io.open(filename,"r"))
	for line in f:lines() do --Снова считываем все строки, параллельно проверяя
		for _,str in ipairs(tocomment) do --обходим все строки, которые нужно закомментировать
			local a,b=string.find(line,str,1,true)
			if a then --если есть совпадение то...
				line=string.sub(line,1,a-1).."--"..str..string.sub(line,b+1)
				break --комментируем и прерываем цикл
			end
		end
		table.insert(content,line)
	end
	f:close()
	f = assert(io.open(filename,"w")) --Формируем новый language.lua с отключёнными строками
	for _,str in ipairs(content) do
		f:write(str.."\n")
	end
	f:close()
	return true
end
local languageluapath ="scripts/languages/language.lua"

if language_lua_has_rusification(languageluapath) then --Если в language.lua подключается русификация
	local OldStart=GLOBAL.Start --Переопределяем функцию, после выполнения которой можно будет вывести попап и перезагрузиться
	function Start() 
		OldStart()
		local a,b="/","\\"
		if GLOBAL.PLATFORM == "NACL" or GLOBAL.PLATFORM == "PS4" or GLOBAL.PLATFORM == "LINUX_STEAM" or GLOBAL.PLATFORM == "OSX_STEAM" then
			a,b=b,a
		end
		local text="В файле "..string.gsub("data/"..languageluapath,a,b).."\nнайдено подключение другой локализации.\nЭто подключение было деактивировано."
		local PopupDialogScreen = GLOBAL.require "screens/popupdialog"
	        GLOBAL.TheFrontEnd:PushScreen(PopupDialogScreen("Обнаружена посторонняя локализация", text,
			{{text="Понятно", cb = function() GLOBAL.TheFrontEnd:PopScreen() GLOBAL.SimReset() end}}))
	end
	GLOBAL.Start=Start
end








--Добавление русских символов в список доступных из консоли
AddClassPostConstruct("screens/consolescreen", function(self) --Выполняем подмену шрифта в спиннере из-за глупой ошибки разрабов в этом виджете
	local NewConsoleValidChars=[[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯІіЇїЄєҐґ]]
	self.console_edit:SetCharacterFilter( NewConsoleValidChars )
end)


Assets={
	Asset("ATLAS",MODROOT.."images/gradient.xml"), --Градиент на слишком длинных строках лога в настройках перевода
	Asset("ATLAS",MODROOT.."images/rus_mapgen.xml"), --Русифицированные пиктограммы в окне генерирования нового мира
	--Персонажи
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
	Asset("ATLAS",MODROOT.."images/eyebutton.xml") --Кнопка с глазом
	}




--В этой функции происходит загрузка, подключение и применение русских шрифтов
function ApplyRussianFonts()
	--Имена шрифтов, которые нужно загрузить.
	local RusFontsFileNames={"talkingfont__ru.zip",
				 "stint-ucr50__ru.zip",
				 "stint-ucr20__ru.zip",
				 "opensans50__ru.zip",
				 "belisaplumilla50__ru.zip",
				 "belisaplumilla100__ru.zip",
				 "buttonfont__ru.zip"}

	--ЭТАП ВЫГРУЗКИ: Вначале выгружаем шрифты, если они были загружены

	--Возвращаем в глобальные переменные шрифтов родные алиасы, которые точно работают,
	--чтобы не выкинуло при перезагрузке
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

	--Выгружаем шрифт, и префаб под него
	for i,FileName in ipairs(RusFontsFileNames) do
		GLOBAL.TheSim:UnloadFont("rusfont"..tostring(i))
	end
	GLOBAL.TheSim:UnloadPrefabs({"rusfonts"})


	--ЭТАП ЗАГРУЗКИ: Загружаем шрифты по новой

	--Формируем список ассетов
	local RusFontsAssets={}
	for i,FileName in ipairs(RusFontsFileNames) do 
		table.insert(RusFontsAssets,GLOBAL.Asset("FONT",MODROOT.."fonts/"..FileName))
	end

	--Создаём префаб, регистриуем его и загружаем
	local RusFontsPrefab=GLOBAL.Prefab("common/rusfonts", nil, RusFontsAssets)
	GLOBAL.RegisterPrefabs(RusFontsPrefab)
	GLOBAL.TheSim:LoadPrefabs({"rusfonts"})

	--Формируем список связанных с файлами алиасов
	for i,FileName in ipairs(RusFontsFileNames) do
		GLOBAL.TheSim:LoadFont(MODROOT.."fonts/"..FileName, "rusfont"..tostring(i))
	end
	--Вписываем в глобальные переменные шрифтов наши алиасы
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

--Вставляем функцию, подключающую русские шрифты
local OldRegisterPrefabs=GLOBAL.ModManager.RegisterPrefabs --Подменяем функцию,в которой нужно подгрузить шрифты и исправить глобальные шрифтовые константы
local function NewRegisterPrefabs(self)
	OldRegisterPrefabs(self)
	ApplyRussianFonts()
end
GLOBAL.ModManager.RegisterPrefabs=NewRegisterPrefabs

--Необходимо подключить русские шрифты в окне создания нового мира
AddClassPostConstruct("screens/worldgenscreen", function(self)
	ApplyRussianFonts()
	--Обновляем два текстовых элемента, которые успели инициализироваться
	self.worldgentext:SetFont(GLOBAL.TITLEFONT)
	self.flavourtext:SetFont(GLOBAL.UIFONT)
end)




function GLOBAL.ChaptersListInit()
	return {
	{id="181337", text="Меню и сообщения",			name="ui"},
	{id="181142", text="Реплики Максвелла",			name="speech_maxwell"},
	{id="181335", text="Реплики Вуди", 			name="speech_woodie"},
	{id="181143", text="Реплики Венди",			name="speech_wendy"},
	{id="181144", text="Реплики Уикерботтом",		name="speech_wickerbottom"},
	{id="181145", text="Реплики Уиллоу",			name="speech_willow"},
	{id="181333", text="Реплики Уилсона",			name="speech_wilson"},
	{id="181334", text="Реплики Вольфганга",		name="speech_wolfgang"},
	{id="181336", text="Реплики WX-78",			name="speech_wx78"},
	{id="181210", text="Дополнительный текст",		name="misc"},
	{id="181139", text="Названия предметов",		name="names"},
	{id="181132", text="Игровые действия",			name="actions"},
	{id="181155", text="Имена зверей",			name="animalnames"},
	{id="181156", text="Реплики зверей",			name="animaltalks"},
	{id="181135", text="Описание персонажей",		name="character"},
	{id="181136", text="Реплики топора Люси",		name="lucy"},
	{id="181137", text="Дополнительные реплики Максвелла",	name="maxwell_misc"},
	{id="181140", text="Описания рецептов",			name="recipies"}  
	}
end
GLOBAL.chapterslist=GLOBAL.ChaptersListInit()


GLOBAL.UpdatePeriod={"OncePerLaunch","OncePerDay","OncePerWeek","OncePerMonth","Never"}


--Пытается сформировать правильные окончания в словах названия предмета str1 в соответствии действию action
function rebuildname(str1,action,objectname)
	local function repsubstr(str,pos,substr)--вставить подстроку substr в строку str в позиции pos
		pos=pos-1
		return string.sub(str,1,pos)..substr..string.sub(str,pos+#substr+1,#str)
	end
	if not str1 then
		return nil
	end
	local 	sogl=  {['б']=1,['в']=1,['г']=1,['д']=1,['ж']=1,['з']=1,['к']=1,['л']=1,['м']=1,['н']=1,['п']=1,
			['р']=1,['с']=1,['т']=1,['ф']=1,['х']=1,['ц']=1,['ч']=1,['ш']=1,['щ']=1}
	local resstr=""
	local delimetr
	local wasnoun=false
	for str in string.gmatch(str1.." ","[А-Яа-яЁёA-Za-z0-9%%'%.]+[%s-]") do
		delimetr=string.sub(str,#str)
		str=string.sub(str,1,#str-1)
		if action=="WALKTO" then --идти к
			if string.sub(str,#str-1)=="ая" and resstr=="" then
				str=repsubstr(str,#str-1,"ой")
			elseif string.sub(str,#str-1)=="ая" then
				str=repsubstr(str,#str-1,"ей")
			elseif string.sub(str,#str-1)=="яя" then
				str=repsubstr(str,#str-1,"ей")
			elseif string.sub(str,#str-1)=="ец" then
				str=repsubstr(str,#str-1,"цу")
			elseif string.sub(str,#str-1)=="ый" then
				str=repsubstr(str,#str-1,"ому")
			elseif string.sub(str,#str-1)=="ий" then
				str=repsubstr(str,#str-1,"ему")
			elseif string.sub(str,#str-1)=="ое" then
				str=repsubstr(str,#str-1,"ому")
			elseif string.sub(str,#str-1)=="ее" then
				str=repsubstr(str,#str-1,"ему")
			elseif string.sub(str,#str-1)=="ые" then
				str=repsubstr(str,#str-1,"ым")
			elseif string.sub(str,#str-1)=="ой" and resstr=="" then
				str=repsubstr(str,#str-1,"ому")
			elseif string.sub(str,#str-1)=="ья" and resstr=="" then
				str=repsubstr(str,#str-1,"ьей")
			elseif string.sub(str,#str-2)=="орь" then
				str=string.sub(str,1,#str-3).."рю"
			elseif string.sub(str,#str-1)=="ек" then
				str=string.sub(str,1,#str-2).."ку"
				wasnoun=true
			elseif string.sub(str,#str-2)=="ень" then
				str=string.sub(str,1,#str-3).."ню"
			elseif string.sub(str,#str-1)=="ок" then
				str=repsubstr(str,#str-1,"ку")
				wasnoun=true
			elseif string.sub(str,#str-1)=="ть" then
				str=repsubstr(str,#str,"и")
				wasnoun=true
			elseif string.sub(str,#str-1)=="вь" then
				str=repsubstr(str,#str,"и")
				wasnoun=true
			elseif string.sub(str,#str-1)=="ль" then
				str=repsubstr(str,#str,"и")
				wasnoun=true
			elseif string.sub(str,#str-1)=="зь" then
				str=repsubstr(str,#str,"и")
				wasnoun=true
			elseif string.sub(str,#str-1)=="нь" then
				str=repsubstr(str,#str,"ю")
				wasnoun=true
			elseif string.sub(str,#str-1)=="рь" then
				str=repsubstr(str,#str,"ю")
				wasnoun=true
			elseif string.sub(str,#str-1)=="ьи" then
				str=str.."м"
			elseif string.sub(str,#str-1)=="ки" and not wasnoun then
				str=repsubstr(str,#str,"ам")
				wasnoun=true
			elseif string.sub(str,#str)=="ы" and not wasnoun then
				str=repsubstr(str,#str,"ам")
				wasnoun=true
			elseif string.sub(str,#str)=="ы" and not wasnoun then
				str=repsubstr(str,#str,"ам")
				wasnoun=true
			elseif string.sub(str,#str)=="а" and not wasnoun then
				str=repsubstr(str,#str,"е")
				wasnoun=true
			elseif string.sub(str,#str)=="я" and not wasnoun then
				str=repsubstr(str,#str,"е")
				wasnoun=true
			elseif string.sub(str,#str)=="о" and not wasnoun then
				str=repsubstr(str,#str,"у")
				wasnoun=true
			elseif string.sub(str,#str-1)=="це" and not wasnoun then
				str=repsubstr(str,#str-1,"цу")
				wasnoun=true
			elseif string.sub(str,#str)=="е" and not wasnoun then
				str=repsubstr(str,#str,"ю")
				wasnoun=true
			elseif sogl[string.sub(str,#str)] and not wasnoun then
				str=str.."у"
				wasnoun=true
			end
		elseif action and objectname and (objectname=="pigman" or objectname=="bunnyman") then --Изучить применительно к имени свиньи или кролика
			if string.sub(str,#str-2)=="нок" then
				str=string.sub(str,1,#str-2).."ка"
			elseif string.sub(str,#str-2)=="лец" then
				str=string.sub(str,1,#str-2).."ьца"
			elseif string.sub(str,#str-2)=="ный" then
				str=string.sub(str,1,#str-2).."ого"
			elseif string.sub(str,#str-1)=="ец" then
				str=string.sub(str,1,#str-2).."ца"
			elseif string.sub(str,#str)=="а" then
				str=string.sub(str,1,#str-1).."у"
			elseif string.sub(str,#str)=="я" then
				str=string.sub(str,1,#str-1).."ю"
			elseif string.sub(str,#str)=="ь" then
				str=string.sub(str,1,#str-1).."я"
			elseif string.sub(str,#str)=="й" then
				str=string.sub(str,1,#str-1).."я"
			elseif sogl[string.sub(str,#str)] then
				str=str.."а"
			end
		elseif action then --Изучить
			if string.sub(str,#str-1)=="ая" then
				str=repsubstr(str,#str-1,"ую")
			elseif string.sub(str,#str-1)=="яя" then
				str=repsubstr(str,#str-1,"юю")
			elseif string.sub(str,#str)=="а" then
				str=repsubstr(str,#str,"у")
			elseif string.sub(str,#str)=="я" then
				str=repsubstr(str,#str,"ю")
			end
		end
		resstr=resstr..str..delimetr
	end
	resstr=string.sub(resstr,1,#resstr-1)
	return resstr
end
GLOBAL.testname=function(name)
	print("Идти к "..rebuildname(name,"WALKTO"))
	print("Осмотреть "..rebuildname(name,"DEFAULTACTION"))
end


--Сохраняет в файле fn все имена с действием, указанным в параметре action)
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
			s1="Изучить "
		elseif action=="WALKTO" then
			s1="Идти к "
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



GLOBAL.russiannames={} --Таблица с особыми формами названий предметов в различных падежах
GLOBAL.actionstosave={} --Таблица сохраняет то-же самое, но является массивом и нужна для сохранения po

GLOBAL.shouldbecapped={} --Таблица, в которой находится список названий, первое слово которых пишется с большой буквы при склонении.

--Загружает список имён, которые должны начинаться с заглавной буквы. Список должен состоять из названий префабов.
local function loadcappednames(data)
	GLOBAL.shouldbecapped={}
	local filename = GLOBAL.RussificationStorePath..pofilename
	if (data and #data==0) or not GLOBAL.kleifileexists(filename) then return nil end
	local insection=false
	local function parseline(line)
		line=escapeR(line)
		if string.sub(line,1,10)=="# --------" then
			insection=string.find(line,"Должны начинаться с заглавной буквы",1,true)
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

--Загружает исправленные названния предметов в нужном падеже из po файла. Если указана data, то парсится она
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
		if string.sub(line,1,10)=="# --------" then --Возможно начинается сегмент с одним из действий
			action=string.match(line,"Действие%s+(.*)%s*$") --Пытаемся вычленить название действия
			if action then
				action=action:upper()
				if action=="DEFAULTACTION" then
					predcessorword="Изучить"
				elseif action=="WALKTO" then
					predcessorword="Идти к"
				else --все другие действия
					predcessorword=GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.ACTIONS."..action] or ""
				end
				GLOBAL.actionstosave[action]={} --создаём таблицу в текущем виде действий.
			end
		elseif action and line~="" and string.sub(line,1,1+#predcessorword)=="#"..predcessorword then
			local translation=string.match(line,predcessorword.." (.-)\t") 
			local original=string.match(line,"\t([^\t]+)\t") 
			local path=string.match(line,"\t([^\t]-)$")
			if BuildErrorLog and path~="OTHER" then
				if not STRINGS.NAMES[path] and not errorlog[path] then
					f:write("Не найден предмет "..tostring(path).."\n")
					errorlog[path]=true
				elseif GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.NAMES."..path]~=original and not errorlog[path] then
					f:write("На notabenoid изменилось название предмета "..tostring(original).." ("..tostring(path)..")".." на "..GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.NAMES."..path].."\n")
					errorlog[path]=true
				end
			end
			table.insert(GLOBAL.actionstosave[action],{pth=path,trans=translation,orig=original})
			if GLOBAL.russiannames[original] then
				GLOBAL.russiannames[original][action]=translation
			else
				GLOBAL.russiannames[original]={}
				GLOBAL.russiannames[original]["DEFAULT"]=STRINGS.NAMES[path] --вставляем оригинальное имя из ро
				GLOBAL.russiannames[original].path=path --добавляем путь
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


GLOBAL.perishablerus={} --Таблица с исправленными качествами предметов
GLOBAL.perishableforsave={} --Таблица сохраняет то-же самое, но является массивом и нужна для сохранения в правильной последовательности
                                    
--Загружает из po файла список правильных слов-качеств для предметов
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
		elseif insection and string.sub(line,1,7)=="#Несвеж" then
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



--Делаем бекап названия версии игры
local UPDATENAME=GLOBAL.STRINGS.UI.MAINSCREEN.UPDATENAME

--Загружаем русификацию
LoadPOFile(GLOBAL.RussificationStorePath..pofilename, "ru")

--Восстанавливаем название версии игры из бекапа
GLOBAL.LanguageTranslator.languages["ru"]["STRINGS.UI.MAINSCREEN.UPDATENAME"]=UPDATENAME

--Перегоняем её в STRINGS
GLOBAL.TranslateStringTable(GLOBAL.STRINGS)



loadcappednames() --Загружаем имена, которые должны оставаться заглавными. Должно быть перед применением перевода в STRINGS

LoadFixedAdjectives() --загружаем исправленные качества продуктов

loadfixednames(false) --загружаем исключения склонений


--printnames("datelniy","DEFAULTACTION")
--printnames("tworitelniy","WALKTO")

--Отладочная функция, генерирует и сохраняет список реплик Уилсона, в которых не должно быть гендерной принадлежности
local function find_wilson_unigender_strings(include_translation)
	local f=assert(io.open(MODROOT.."wilson_unigender_strings.txt","w"))
	local wendy,wickerbottom,willow={},{},{}
	for key,val in pairs(GLOBAL.LanguageTranslator.languages["ru"]) do --Ищем женские реплики
		if string.sub(key,1,24)=="STRINGS.CHARACTERS.WENDY" then wendy[key]=val end
		if string.sub(key,1,31)=="STRINGS.CHARACTERS.WICKERBOTTOM" then wickerbottom[key]=val end
		if string.sub(key,1,25)=="STRINGS.CHARACTERS.WILLOW" then willow[key]=val end
	end
	for key,val in pairs(GLOBAL.LanguageTranslator.languages["ru"]) do
		if string.sub(key,1,26)=="STRINGS.CHARACTERS.GENERIC" then --Если это фраза Уилсона
			if not wendy["STRINGS.CHARACTERS.WENDY"..string.sub(key,27)] or --и её нет у одного из женских персонажей
			   not wickerbottom["STRINGS.CHARACTERS.WICKERBOTTOM"..string.sub(key,27)] or
			   not willow["STRINGS.CHARACTERS.WILLOW"..string.sub(key,27)] then --то сохраняем её
				f:write(key)
				if not wendy["STRINGS.CHARACTERS.WENDY"..string.sub(key,27)] then f:write(" нет у Wendy") end
				if not wickerbottom["STRINGS.CHARACTERS.WICKERBOTTOM"..string.sub(key,27)] then f:write(" нет у Wickerbottom") end
				if not willow["STRINGS.CHARACTERS.WILLOW"..string.sub(key,27)] then f:write(" нет у Willow") end
				f:write("\n")
				if include_translation then f:write(val.."\n\n") end
			end
		end
	end
	f:close()
end

--find_wilson_unigender_strings(true)

--Отладочная функция, выводящая имена всех зверей с действиями в файл AnimalNamesCheck.txt
--Нужна для проверки правильности склонения имён
local function AnimalNamesCheck()
	local f=assert(io.open(MODROOT.."AnimalNamesCheck.txt","w"))
	f:write("------------Зайцы-------------\n\n")
	for key,name in pairs(STRINGS.BUNNYMANNAMES) do
		f:write(key.." "..name..":\n")
		f:write("\tИдти к "..rebuildname(name,"WALKTO","bunnyman").."\n")
		f:write("\tОсмотреть "..rebuildname(name,"DEFAULTACTION","bunnyman").."\n")
	end	
	f:write("\n------------Свиньи-------------\n\n")
	for key,name in pairs(STRINGS.PIGNAMES) do
		f:write(key.." "..name..":\n")
		f:write("\tИдти к "..rebuildname(name,"WALKTO","pigman").."\n")
		f:write("\tОсмотреть "..rebuildname(name,"DEFAULTACTION","pigman").."\n")
	end	
	f:close()
end

--AnimalNamesCheck()




--Новая версия функции, выдающей качество предмета
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
GLOBAL.EntityScript["GetAdjective"]=GetAdjectiveNew --подменяем функцию, выводящую качества продуктов



local GetDisplayNameOld=GLOBAL.EntityScript["GetDisplayName"] --сохраняем старую функцию, выводящую название предмета
function GetDisplayNameNew(self) --Подмена функции, выводящей название предмета. В ней реализовано склонение в зависимости от действия (переменная аct)
	local name=GetDisplayNameOld(self)

	                       
	local act=GetPlayer().components.playercontroller:GetLeftMouseAction() --Получаем текущее действие
	local itisblueprint=false
	if name:sub(-10)==" Blueprint" then --Особое исключительное написание для чертежей
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
		if not itisblueprint and self.prefab and self.prefab~="pigman" and self.prefab~="bunnyman" and not GLOBAL.shouldbecapped[self.prefab] and name and type(name)=="string" and #name>0 then --меняем первый символ названия предмета в нижний регистр
			local firstletter=string.byte(name)
			if firstletter>=0xC0 and firstletter<0xE0 then firstletter=firstletter+0x20
				elseif firstletter==0xA8 then firstletter=firstletter+0x10 end
			name=(string.char(firstletter)):lower()..string.sub(name,2)
		end
		if itisblueprint then name="чертёж предмета \""..name.."\"" end
	else
	        if itisblueprint then name="Чертёж предмета \""..name.."\"" end
	end
    return name
end
GLOBAL.EntityScript["GetDisplayName"]=GetDisplayNameNew --подменяем на новую



--Переопределяем функцию, выводящую "Создать ...", когда устанавливается на землю крафт-предмет типа палатки.
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
		if not GLOBAL.shouldbecapped[self.placer_recipe.name] and name and type(name)=="string" and #name>0 then --меняем первый символ названия предмета в нижний регистр
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



local oldSelectPortrait --Старая функция выбора портрета в меню выбора персонажа
local function newSelectPortrait(self,portrait)
	oldSelectPortrait(self,portrait) --Запускаем оригинальную функцию
	if self.heroportait and self.heroportait.texture then
		local list={["locked"]=1,["wickerbottom"]=1,["waxwell"]=1,["willow"]=1,["wilson"]=1,["woodie"]=1,["wes"]=1,["wolfgang"]=1,["wendy"]=1}
		local name=string.sub(self.heroportait.texture,1,-5)
		if list[name] then
			self.heroportait:SetTexture("images/rus_"..name..".xml", "rus_"..name..".tex")
		end
	end
end
--Подменяем функцию показа портрета в меню выбора персонажа
AddClassPostConstruct("screens/characterselectscreen", function(self)
	oldSelectPortrait=self["SelectPortrait"]
	self["SelectPortrait"]=newSelectPortrait
	self:SelectPortrait(1) --Нужно, чтобы обновить то, что уже успело показаться
end)




local oldRefreshOptions --Старая функция заполнения опций в меню настроек карты
local function newRefreshOptions(self) --Новая функция
	oldRefreshOptions(self) --Запускаем оригинальную функцию
	if self.optionspanel then
		local list={["day.tex"]=1,["season.tex"]=1,["season_start.tex"]=1,["world_size.tex"]=1,["world_branching.tex"]=1,["world_loop.tex"]=1}
		for v in pairs(self.optionspanel:GetChildren()) do --Перебираем ячейки
			if tostring(v)=="option" then
				for prefab in pairs(v:GetChildren()) do --Ищем картинку и спиннер в ячейке
					if prefab.name and prefab.name:upper()=="IMAGE" then
						if list[prefab.texture] then
							prefab:SetTexture(MODROOT.."images/rus_mapgen.xml", "rus_"..prefab.texture)
						end
					elseif prefab.name and prefab.name:upper()=="SPINNER" and prefab.options then
						local shouldbeupdated=false
						for _,opt in ipairs(prefab.options) do --изучаем опции
							local words=string.split(opt.text," ") --разбиваем на слова
							opt.text=words[1]
							if #words>1 then --если слов несколько
								if opt.text==STRINGS.UI.SANDBOXMENU.SLIDELONG then
									if words[2]==STRINGS.UI.SANDBOXMENU.DAY or words[2]==STRINGS.UI.SANDBOXMENU.DUSK then
										opt.text=opt.text:sub(1,-2).."й"
									elseif words[2]==STRINGS.UI.SANDBOXMENU.NIGHT or words[2]==STRINGS.UI.SANDBOXMENU.WINTER then
										opt.text=opt.text:sub(1,-3).."ая"
									elseif words[2]==STRINGS.UI.SANDBOXMENU.SUMMER then
										opt.text=opt.text:sub(1,-3).."ое"
									end
								end
								for i=2,#words do --все последующие с маленькой буквы
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
--Подменяем функцию обновления в интерфейсе настройки новой карты
AddClassPostConstruct("screens/customizationscreen", function(self)
	oldRefreshOptions=self["RefreshOptions"]
	self["RefreshOptions"]=newRefreshOptions
	self:RefreshOptions() --Нужно, чтобы обновить то, что уже успело показаться
end)




--Добавление кнопки в опциях игры
local OldShowMenu --Старая функция показа меню для mainscreen
function NewShowMenu(self,menu_items) --Новая функция
	for i,v in ipairs(menu_items) do --ищем кнопку "управление", и вставляем после неё "Русификация"
		if v.text==STRINGS.UI.MAINSCREEN.CONTROLS then
			local LanguageOptions = GLOBAL.require "screens/LanguageOptions"
			table.insert( menu_items, i+1, {text="Русификация", cb= function() TheFrontEnd:PushScreen(LanguageOptions()) end})
			break
		end
	end
	OldShowMenu(self,menu_items) --Запускаем оригинальную функцию
end

AddClassPostConstruct("screens/mainscreen", function(self) --Выполняем подмену, чтобы показывалась кнопка "Русификация"
	OldShowMenu=self["ShowMenu"]
	self["ShowMenu"]=NewShowMenu
end)


--Исправление бага с шрифтом в спиннерах
AddClassPostConstruct("widgets/spinner", function(self, options, width, height, textinfo, ...) --Выполняем подмену шрифта в спиннере из-за глупой ошибки разрабов в этом виджете
	if textinfo then return end
	self.text:SetFont(GLOBAL.BUTTONFONT)
end)


--Исправляем жёстко зашитые надписи на кнопках в казане и телепорте.
AddClassPostConstruct("widgets/containerwidget", function(self)
	self.oldOpen=self.Open
	local function newOpen(self, container, doer)
		self:oldOpen(container, doer)
		if self.button then
			if self.button:GetText()=="Cook" then self.button:SetText("Готовить") end
			if self.button:GetText()=="Activate" then self.button:SetText("Запустить") end
		end
	end
	self.Open=newOpen
end)


AddClassPostConstruct("widgets/recipepopup", function(self) --Уменьшаем шрифт описания рецепта в попапе рецептов
	if not self.desc then return end
	self.desc:SetSize(28)
	self.desc:SetRegionSize(64*3+30,130)
end)


--Чуть-чуть раздвигаем портрет и надпись в меню загрузки игр
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

--Уменьшаем размер текста в заголовке деталей записи
AddClassPostConstruct("screens/slotdetailsscreen", function(self)
	self.text:SetSize(47)
end)

--Уменьшаем шрифт в заголовке морга
AddClassPostConstruct("screens/morguescreen", function(self) 
	if self.obits_titles then
		for str in pairs(self.obits_titles:GetChildren()) do
			if type(str)=="table" and str.name and str.name=="Text" then
				str:SetSize(28)
			end
		end
	end
end)


--Для тех, кто пользуется ps4 или NACL должна быть возможность сохранять не в ини файле, а в облаке.
--Для этого дорабатываем функционал стандартного класса PlayerProfile
local function SetLocalizaitonValue(self,name,value) --Метод, сохраняющий опцию с именем name и значением value
        local USE_SETTINGS_FILE = GLOBAL.PLATFORM ~= "PS4" and GLOBAL.PLATFORM ~= "NACL"
 	if USE_SETTINGS_FILE then
		TheSim:SetSetting("translation", tostring(name), tostring(value))
	else
		self:SetValue(tostring(name), tostring(value))
		self.dirty = true
		self:Save() --Сохраняем сразу, поскольку у нас нет кнопки "применить"
	end
end
local function GetLocalizaitonValue(self,name) --Метод, возвращающий значение опции name
        local USE_SETTINGS_FILE = GLOBAL.PLATFORM ~= "PS4" and GLOBAL.PLATFORM ~= "NACL"
 	if USE_SETTINGS_FILE then
		return TheSim:GetSetting("translation", tostring(name))
	else
		return self:GetValue(tostring(name))
	end
end

--Расширяем функционал PlayerProfile дополнительной инициализацией двух методов и заданием дефолтных значений опций нашего перевода.
AddGlobalClassPostConstruct("playerprofile", "PlayerProfile", function(self)
        local USE_SETTINGS_FILE = GLOBAL.PLATFORM ~= "PS4" and GLOBAL.PLATFORM ~= "NACL"
 	if not USE_SETTINGS_FILE then
	        self.persistdata.update_is_allowed = true --Разрешено запускать обновление по умолчанию
	        self.persistdata.update_frequency = GLOBAL.UpdatePeriod[3] --Раз в неделю по умолчанию
		local date=GLOBAL.os.date("*t")
		self.persistdata.last_update_date = tostring(date.day.."."..date.month.."."..date.year) --Текущая дата по умолчанию
	end
	self["SetLocalizaitonValue"]=SetLocalizaitonValue --метод задачи значения опции
	self["GetLocalizaitonValue"]=GetLocalizaitonValue --метод получения значения опции
end)



--Загружает главы из нотабеноида
local function DownloadNotabenoidChapters()
	local UpdateRussianDialog = GLOBAL.require "screens/UpdateRussianDialog"
	GLOBAL.TheFrontEnd:PushScreen(UpdateRussianDialog())
end


  

local OldStart=GLOBAL.Start
function Start() --После выполнения этой функции уже можно показывать диалоги.


	OldStart() --Сначала запускаем родную функцию

	local a=GLOBAL.Profile:GetLocalizaitonValue("update_is_allowed")
	
	if not a or a=="true" or a==true then --Если в ini файле есть запись, позволяющая проверять обновления или её вообще нет
		local period=GLOBAL.Profile:GetLocalizaitonValue("update_frequency")
		if not period then --Если нет записи о периоде, то делаем по умолчанию раз в неделю
			period=GLOBAL.UpdatePeriod[3]
			GLOBAL.Profile:SetLocalizaitonValue("update_frequency",period)
		end
		if period==GLOBAL.UpdatePeriod[1] then --При каждом запуске
			DownloadNotabenoidChapters()
		end
		if period~=GLOBAL.UpdatePeriod[5] then --если не выбрано "никогда не обновлять"
			local date=GLOBAL.os.date("*t")
			local date2=GLOBAL.Profile:GetLocalizaitonValue("last_update_date")
			if date2 then --Получили две даты. Сравниваем в зависимости от установленной частоты обновления
				date2=string.split(date2,".")
				if period==GLOBAL.UpdatePeriod[2] then --Раз в день
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
					if period==GLOBAL.UpdatePeriod[3] then --Раз в неделю
						if datedaysum-7>=date2daysum then
							DownloadNotabenoidChapters()
						end
					elseif period==GLOBAL.UpdatePeriod[4] then --Раз в месяц
						if datedaysum-DaysperMonth[tonumber(date2[2])]>=date2daysum then
							DownloadNotabenoidChapters()
						end
					end
				
				end
			else --Нет записи о дате. Значит это скорее всего первое обновление.
				DownloadNotabenoidChapters() 
			end
		end
	end
end
GLOBAL.Start=Start



--Перехватываем функцию закрытия игры для записи в ини файл данных о том, что можно обновляться
local oldshutdown=GLOBAL.Shutdown
function newShutdown()
	GLOBAL.Profile:SetLocalizaitonValue("update_is_allowed", "true") --Если игра выключена с включенным модом, разрешим в следующий раз проверять обновление
	oldshutdown()
end
GLOBAL.Shutdown=newShutdown


