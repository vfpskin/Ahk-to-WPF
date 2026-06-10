; ======================================================================
; themes.ahk -- Centralized Theme Catalog
;
; To add a new theme:
;   1. Add the name to ThemeOrder (controls cycle order)
;   2. Add the color dictionary to ThemeDefs
;
; Each theme needs:
;   base:       Base theme for SetTheme (Dark|Light|Blue|Green|Purple|Red|Orange|Teal)
;   WindowBg:   Main window background
;   SidebarBg:  Sidebar/topbar background
;   Surface:    Card/surface background
;   Surface2:   Alternate/secondary surface
;   Border:     Border color
;   Accent:     Primary accent
;   AccentHover:Accent hover state
;   AccentGlow: Accent glow/highlight
;   TextPrimary:Primary text
;   TextSecondary:Secondary text
;   TextMuted:  Muted/disabled text
;   RowHover:   Row hover background
;   ScrollThumb:Scrollbar thumb
;   Success:    Success state
;   SuccessHover:Success hover
;   Danger:     Danger/error
;   DangerHover:Danger hover
; ======================================================================

ThemeOrder := ["Navy", "Dark", "Light", "Blue", "Green", "Purple", "Red", "Orange", "Teal"]

ThemeDefs := {}

;------------------------------------------------------------------------
; NAVY (default)
;------------------------------------------------------------------------
ThemeDefs["Navy"] := {base:"Dark"
    , WindowBg:"#0A1628", SidebarBg:"#0F1D32", Surface:"#112236", Surface2:"#1A3050"
    , Border:"#2A4A6B", Accent:"#1A78C2", AccentHover:"#1565A8", AccentGlow:"#2196F3"
    , TextPrimary:"#E5F0F7", TextSecondary:"#97BCE1", TextMuted:"#6B8FB5"
    , RowHover:"#152A45", ScrollThumb:"#2A4A6B"
    , Success:"#1A7A4A", SuccessHover:"#166040", Danger:"#C0392B", DangerHover:"#A93226"}

;------------------------------------------------------------------------
; DARK
;------------------------------------------------------------------------
ThemeDefs["Dark"] := {base:"Dark"
    , WindowBg:"#1E1E1E", SidebarBg:"#0F172A", Surface:"#111827", Surface2:"#172033"
    , Border:"#404040", Accent:"#5B9BD5", AccentHover:"#4A87C0", AccentGlow:"#7CB9E8"
    , TextPrimary:"#F0F0F0", TextSecondary:"#AAAAAA", TextMuted:"#64748B"
    , RowHover:"#1F2937", ScrollThumb:"#4B5563"
    , Success:"#22C55E", SuccessHover:"#16A34A", Danger:"#EF4444", DangerHover:"#DC2626"}

;------------------------------------------------------------------------
; LIGHT
;------------------------------------------------------------------------
ThemeDefs["Light"] := {base:"Light"
    , WindowBg:"#F4F4F4", SidebarBg:"#FFFFFF", Surface:"#FFFFFF", Surface2:"#F3F4F6"
    , Border:"#DCDCDC", Accent:"#2E6DA4", AccentHover:"#245A8A", AccentGlow:"#3B82F6"
    , TextPrimary:"#1A1A1A", TextSecondary:"#666666", TextMuted:"#94A3B8"
    , RowHover:"#E5E7EB", ScrollThumb:"#CBD5E1"
    , Success:"#16A34A", SuccessHover:"#15803D", Danger:"#DC2626", DangerHover:"#B91C1C"}

;------------------------------------------------------------------------
; BLUE
;------------------------------------------------------------------------
ThemeDefs["Blue"] := {base:"Blue"
    , WindowBg:"#D6EAF8", SidebarBg:"#DCEFFC", Surface:"#F7FBFF", Surface2:"#EAF3FF"
    , Border:"#AED6F1", Accent:"#0078D4", AccentHover:"#005A9E", AccentGlow:"#3B82F6"
    , TextPrimary:"#0D1117", TextSecondary:"#2471A3", TextMuted:"#5B6B7A"
    , RowHover:"#DBEAFE", ScrollThumb:"#93C5FD"
    , Success:"#059669", SuccessHover:"#047857", Danger:"#DC2626", DangerHover:"#B91C1C"}

;------------------------------------------------------------------------
; GREEN
;------------------------------------------------------------------------
ThemeDefs["Green"] := {base:"Green"
    , WindowBg:"#D5F5E3", SidebarBg:"#EAFBF1", Surface:"#F4FFF8", Surface2:"#E1F9EB"
    , Border:"#A9DFBF", Accent:"#27AE60", AccentHover:"#1E8449", AccentGlow:"#34D399"
    , TextPrimary:"#0D1117", TextSecondary:"#1E8449", TextMuted:"#5F7C6A"
    , RowHover:"#D1FAE5", ScrollThumb:"#6EE7B7"
    , Success:"#16A34A", SuccessHover:"#15803D", Danger:"#DC2626", DangerHover:"#B91C1C"}

;------------------------------------------------------------------------
; PURPLE
;------------------------------------------------------------------------
ThemeDefs["Purple"] := {base:"Purple"
    , WindowBg:"#E8DAEF", SidebarBg:"#F5EEF8", Surface:"#FBF7FD", Surface2:"#F0E6F6"
    , Border:"#D7BDE2", Accent:"#8E44AD", AccentHover:"#7D3C98", AccentGlow:"#A855F7"
    , TextPrimary:"#0D1117", TextSecondary:"#7D3C98", TextMuted:"#6B7280"
    , RowHover:"#F3E8FF", ScrollThumb:"#C4B5FD"
    , Success:"#16A34A", SuccessHover:"#15803D", Danger:"#DC2626", DangerHover:"#B91C1C"}

;------------------------------------------------------------------------
; RED
;------------------------------------------------------------------------
ThemeDefs["Red"] := {base:"Dark"
    , WindowBg:"#1A0D0D", SidebarBg:"#1F0F0F", Surface:"#241212", Surface2:"#331A1A"
    , Border:"#4A2525", Accent:"#E74C3C", AccentHover:"#C0392B", AccentGlow:"#FF6B6B"
    , TextPrimary:"#F5E6E6", TextSecondary:"#C0A0A0", TextMuted:"#8A6060"
    , RowHover:"#2E1818", ScrollThumb:"#4A2525"
    , Success:"#27AE60", SuccessHover:"#1E8449", Danger:"#E74C3C", DangerHover:"#C0392B"}

;------------------------------------------------------------------------
; ORANGE
;------------------------------------------------------------------------
ThemeDefs["Orange"] := {base:"Dark"
    , WindowBg:"#1A120B", SidebarBg:"#1F1610", Surface:"#241A14", Surface2:"#33261E"
    , Border:"#4A362A", Accent:"#E67E22", AccentHover:"#CA6F1E", AccentGlow:"#FFA94D"
    , TextPrimary:"#F0E6DB", TextSecondary:"#BFA898", TextMuted:"#8A7868"
    , RowHover:"#2E1F18", ScrollThumb:"#4A362A"
    , Success:"#27AE60", SuccessHover:"#1E8449", Danger:"#E74C3C", DangerHover:"#C0392B"}

;------------------------------------------------------------------------
; TEAL
;------------------------------------------------------------------------
ThemeDefs["Teal"] := {base:"Teal"
    , WindowBg:"#D1F2EB", SidebarBg:"#E6FFFB", Surface:"#F4FFFD", Surface2:"#DDF7F3"
    , Border:"#A2D9CE", Accent:"#17A589", AccentHover:"#148F77", AccentGlow:"#2DD4BF"
    , TextPrimary:"#0D1117", TextSecondary:"#148F77", TextMuted:"#4B5563"
    , RowHover:"#CCFBF1", ScrollThumb:"#5EEAD4"
    , Success:"#059669", SuccessHover:"#047857", Danger:"#DC2626", DangerHover:"#B91C1C"}
