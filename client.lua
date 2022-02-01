_G.Locale = 'en';

local LanguageDict = {afrikaans = "af",albanian = "sq",amharic = "am",arabic = "ar",armenian = "hy",azerbaijani = "az",bashkir = "ba",basque = "eu",belarusian = "be",bengal = "bn",bosnian = "bs",bulgarian = "bg",burmese = "my",catalan = "ca",cebuano = "ceb",chinese = "zh",croatian = "hr",czech = "cs",danish = "da",dutch = "nl",english = "en",esperanto = "eo",estonian = "et",finnish = "fi",french = "fr",galician = "gl",georgian = "ka",german = "de",greek = "el",gujarati = "gu",creole = "ht",hebrew = "he",hillmari = "mrj",hindi = "hi",hungarian = "hu",icelandic = "is",indonesian = "id",irish = "ga",italian = "it",japanese = "ja",javanese = "jv",kannada = "kn",kazakh = "kk",khmer = "km",kirghiz = "ky",korean = "ko",laotian = "lo",latin = "la",latvian = "lv",lithuanian = "lt",luxembourg = "lb",macedonian = "mk",malagasy = "mg",malayalam = "ml",malay = "ms",maltese = "mt",maori = "mi",marathi = "mr",mari = "mhr",mongolian = "mn",nepalese = "ne",norwegian = "no",papiamento = "pap",persian = "fa",polish = "pl",portuguese = "pt",punjabi = "pa",romanian = "ro",russian = "ru",scottish = "gd",serbian = "sr",sinhalese = "si",slovak = "sk",slovenian = "sl",spanish = "es",sundanese = "su",swahili = "sw",swedish = "sv",tagalog = "tl",tajik = "tg",tamil = "ta",tartar = "tt",telugu = "te",thai = "th",turkish = "tr",udmurt = "udm",ukrainian = "uk",urdu = "ur",uzbek = "uz",vietnamese = "vi",welsh = "cy",xhosa = "xh",yiddish = "yi"}

local LocaleLang = string.lower(_G.Locale or 'en');
local Keys = {};
local ClientKey = Keys[math.random(1, #Keys)];

local Players = game:GetService('Players');
local StarterGui = game:GetService('StarterGui');
local HttpService = game:GetService('HttpService');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Player = Players.LocalPlayer;

local function Test(f)
    local _Test, Output = pcall(f);
    return {
        Success = _Test,
        Message = Output;
    };
end;

local WebSocket = syn.websocket.connect('ws://localhost:3000');

local function Request(u, m, h)
    WebSocket:Send(HttpService:JSONEncode({url=u,method=m,headers=h}));
    local Response = WebSocket.OnMessage:Wait();
    return HttpService:JSONDecode(Response);
end;

StarterGui:SetCore('SendNotification', {
    Title = 'Chat Translator V2',
    Text = string.format('Detected language: %s', LocaleLang),
    Duration = 3
});

local function TestKey()
    local EndPoint = string.format('https://translate.yandex.net/api/v1.5/tr.json/detect?key=%s&text=%s', ClientKey, 'hello');
    local Res = Request(EndPoint);
    return Res.code == 200;
end;

local function DetectLang(m)
    local EndPoint = string.format('https://translate.yandex.net/api/v1.5/tr.json/detect?key=%s&text=%s', ClientKey, HttpService:UrlEncode(m));
    local Res = Request(EndPoint);
    return (Res.lang == '') and LocaleLang or Res.lang;
end;

local function Translate(m, f, t)
    local EndPoint = string.format('https://translate.yandex.net/api/v1.5/tr.json/translate?key=%s&text=%s&lang=%s-%s', ClientKey, HttpService:UrlEncode(m), f, t);
    local Res = Request(EndPoint);
    return Res.text and Res.text[1] or m;
end;

if (not TestKey()) then
    repeat
        ClientKey = Keys[math.random(1, #Keys)];
        wait();
    until TestKey();
end;

local function TranslateFrom(m)
    local _Lang = DetectLang(m);
    if (_Lang and _Lang ~= LocaleLang) then
        return {
            Translate(m, _Lang, LocaleLang),
            _Lang
        };
    else
        return {
            m,
            LocaleLang
        };
    end;
end;

local function Get(p, m)
    local Translated = TranslateFrom(m);
    local Translation, FromLang = Translated[1], Translated[2];
    if (FromLang ~= LocaleLang) then
        StarterGui:SetCore('ChatMakeSystemMessage', {
            Color = Color3.fromRGB(245, 255, 102),
            Text = string.format('[%s->%s] %s: %s', string.upper(FromLang), string.upper(LocaleLang), p.DisplayName, Translation); 
        });
    end;
end;

for _, p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(m)
        Get(p, m);
    end);
end;

Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(m)
        Get(p, m);
    end);
end);

local ChatEnabled = false;
local Target = LocaleLang;

local function TranslateTo(m)
    if LanguageDict[Target] then Target = LanguageDict[Target] end;
    local _Lang = DetectLang(m);
    if (_Lang and _Lang ~= Target) then
        return Translate(m, _Lang, Target);
    else
        return m;
    end;
    return m;
end;

local function DisableChat()
    ChatEnabled = false;
end;

local function EnableChat()
    ChatEnabled = true;
end;

local ChatBar = Player.PlayerGui:WaitForChild('Chat').Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar;
local ChatRemote = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest;
local Connected = {};

local function HookChat(Bar)
    coroutine.wrap(function()
        if (not table.find(Connected, Bar)) then
            local Connection = Bar.FocusLost:Connect(function(e)
                if (e ~= false and Bar.Text ~= '') then
                    local Message = Bar.Text;
                    Bar.Text = '';
                    if (Message == '>d') then
                        DisableChat();
                        return;
                    elseif (string.sub(Message, 1, 1) == '>') and (not string.find(Message, ' ')) then
                        EnableChat();
                        Target = string.sub(Message, 2);
                        return;
                    elseif (ChatEnabled) then
                        Message = TranslateTo(Message);
                        Players:Chat(Message);
                        ChatRemote:FireServer(Message, 'All');
                        return;
                    else
                        Players:Chat(Message);
                        ChatRemote:FireServer(Message, 'All');
                        return;
                    end;
                end;
            end);
        end;
    end)();
end;

HookChat(ChatBar);

local BindHook = Instance.new('BindableEvent');
local _Meta = getrawmetatable(game);
local _NC = _Meta.__namecall;
setreadonly(_Meta, false);

_Meta.__namecall = newcclosure(function(...)
    local Method, Args = getnamecallmethod(), {...};
    if (rawequal(tostring(Args[1]), 'ChatBarFocusChanged') and rawequal(Args[2], true)) then
        if Player.PlayerGui.Chat then
            BindHook:Fire();
        end;
    end;
    return _NC(...);
end);
setreadonly(_Meta, true);

BindHook.Event:Connect(function()
    ChatBar = Player.PlayerGui:WaitForChild('Chat').Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar;
    HookChat(ChatBar);
end);
